// SPDX-License-Identifier: GPL-2.0-or-later
/*
 * Harbor SPI controller driver
 *
 * Register map:
 *   0x00: CTRL    (RW) - enable, CPOL, CPHA, loopback
 *   0x04: STATUS  (RO) - busy, tx_empty, rx_ready
 *   0x08: DATA    (RW) - write=TX, read=RX
 *   0x0C: DIVIDER (RW) - clock divider
 *   0x10: CS      (RW) - chip select output
 */

#include <linux/module.h>
#include <linux/platform_device.h>
#include <linux/spi/spi.h>
#include <linux/io.h>
#include <linux/of.h>
#include <linux/clk.h>

#define HARBOR_SPI_CTRL	   0x00
#define HARBOR_SPI_STATUS  0x04
#define HARBOR_SPI_DATA	   0x08
#define HARBOR_SPI_DIVIDER 0x0C
#define HARBOR_SPI_CS	   0x10

#define HARBOR_SPI_CTRL_ENABLE BIT(0)
#define HARBOR_SPI_CTRL_CPOL   BIT(1)
#define HARBOR_SPI_CTRL_CPHA   BIT(2)
#define HARBOR_SPI_CTRL_LOOP   BIT(3)

#define HARBOR_SPI_ST_BUSY     BIT(0)
#define HARBOR_SPI_ST_TX_EMPTY BIT(1)
#define HARBOR_SPI_ST_RX_READY BIT(2)

struct harbor_spi {
	void __iomem *base;
	struct spi_controller *host;
	unsigned int freq;
};

static void harbor_spi_set_cs(struct spi_device *spi, bool enable)
{
	struct harbor_spi *hs = spi_controller_get_devdata(spi->controller);
	u32 cs;

	cs = readl(hs->base + HARBOR_SPI_CS);
	if (enable)
		cs &= ~BIT(spi_get_chipselect(spi, 0));
	else
		cs |= BIT(spi_get_chipselect(spi, 0));
	writel(cs, hs->base + HARBOR_SPI_CS);
}

static int harbor_spi_wait_busy(struct harbor_spi *hs)
{
	int timeout = 10000;

	while (readl(hs->base + HARBOR_SPI_STATUS) & HARBOR_SPI_ST_BUSY) {
		if (--timeout == 0)
			return -ETIMEDOUT;
		cpu_relax();
	}
	return 0;
}

static int harbor_spi_transfer_one(struct spi_controller *host,
				   struct spi_device *spi,
				   struct spi_transfer *t)
{
	struct harbor_spi *hs = spi_controller_get_devdata(host);
	const u8 *tx = t->tx_buf;
	u8 *rx = t->rx_buf;
	int i, ret;

	/* Set clock divider */
	if (t->speed_hz && hs->freq) {
		u32 div = (hs->freq / (2 * t->speed_hz)) - 1;
		writel(div, hs->base + HARBOR_SPI_DIVIDER);
	}

	for (i = 0; i < t->len; i++) {
		/* Write TX byte */
		writel(tx ? tx[i] : 0, hs->base + HARBOR_SPI_DATA);

		/* Wait for transfer to complete */
		ret = harbor_spi_wait_busy(hs);
		if (ret)
			return ret;

		/* Read RX byte */
		if (rx)
			rx[i] = readl(hs->base + HARBOR_SPI_DATA) & 0xFF;
	}

	return 0;
}

static int harbor_spi_probe(struct platform_device *pdev)
{
	struct harbor_spi *hs;
	struct spi_controller *host;
	struct clk *clk;
	u32 num_cs = 1;
	int ret;

	host = devm_spi_alloc_host(&pdev->dev, sizeof(*hs));
	if (!host)
		return -ENOMEM;

	hs = spi_controller_get_devdata(host);

	hs->base = devm_platform_ioremap_resource(pdev, 0);
	if (IS_ERR(hs->base))
		return PTR_ERR(hs->base);

	clk = devm_clk_get_optional_enabled(&pdev->dev, NULL);
	if (IS_ERR(clk))
		return PTR_ERR(clk);
	hs->freq = clk ? clk_get_rate(clk) : 0;

	of_property_read_u32(pdev->dev.of_node, "num-cs", &num_cs);

	host->bus_num = -1;
	host->num_chipselect = num_cs;
	host->mode_bits = SPI_CPOL | SPI_CPHA | SPI_LOOP;
	host->bits_per_word_mask = SPI_BPW_MASK(8);
	host->set_cs = harbor_spi_set_cs;
	host->transfer_one = harbor_spi_transfer_one;
	host->dev.of_node = pdev->dev.of_node;

	/* Enable controller */
	writel(HARBOR_SPI_CTRL_ENABLE, hs->base + HARBOR_SPI_CTRL);

	ret = devm_spi_register_controller(&pdev->dev, host);
	if (ret)
		return ret;

	platform_set_drvdata(pdev, hs);
	return 0;
}

static const struct of_device_id harbor_spi_of_match[] = {
    {.compatible = "harbor,spi"}, {}};
MODULE_DEVICE_TABLE(of, harbor_spi_of_match);

static struct platform_driver harbor_spi_driver = {
    .probe = harbor_spi_probe,
    .driver =
	{
	    .name = "harbor-spi",
	    .of_match_table = harbor_spi_of_match,
	},
};
module_platform_driver(harbor_spi_driver);

MODULE_AUTHOR("Midstall Software");
MODULE_DESCRIPTION("Harbor SPI controller driver");
MODULE_LICENSE("GPL");
