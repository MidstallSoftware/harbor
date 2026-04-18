// SPDX-License-Identifier: GPL-2.0-or-later
/*
 * Harbor SDHCI controller driver
 *
 * Register map:
 *   0x00: CTRL      (RW) - enable, bus width
 *   0x04: STATUS    (RO) - card_detect, busy
 *   0x08: CLK_DIV   (RW) - clock divider
 *   0x0C: CMD       (RW) - command index + trigger
 *   0x10: CMD_ARG   (RW) - command argument
 *   0x14: RESP0     (RO) - response bits 31:0
 *   0x18: RESP1     (RO) - response bits 63:32
 *   0x1C: RESP2     (RO) - response bits 95:64
 *   0x20: RESP3     (RO) - response bits 127:96
 *   0x24: DATA      (RW) - data FIFO
 *   0x28: BLK_SIZE  (RW) - block size
 *   0x2C: BLK_COUNT (RW) - block count
 *   0x30: INT_STATUS (W1C) - interrupt status
 *   0x34: INT_ENABLE (RW) - interrupt enable
 */

#include <linux/module.h>
#include <linux/platform_device.h>
#include <linux/mmc/host.h>
#include <linux/mmc/mmc.h>
#include <linux/io.h>
#include <linux/of.h>
#include <linux/clk.h>
#include <linux/interrupt.h>
#include <linux/scatterlist.h>

#define HARBOR_SD_CTRL	     0x00
#define HARBOR_SD_STATUS     0x04
#define HARBOR_SD_CLK_DIV    0x08
#define HARBOR_SD_CMD	     0x0C
#define HARBOR_SD_CMD_ARG    0x10
#define HARBOR_SD_RESP0	     0x14
#define HARBOR_SD_RESP1	     0x18
#define HARBOR_SD_RESP2	     0x1C
#define HARBOR_SD_RESP3	     0x20
#define HARBOR_SD_DATA	     0x24
#define HARBOR_SD_BLK_SIZE   0x28
#define HARBOR_SD_BLK_COUNT  0x2C
#define HARBOR_SD_INT_STATUS 0x30
#define HARBOR_SD_INT_ENABLE 0x34

#define HARBOR_SD_ST_CARD_DETECT BIT(0)
#define HARBOR_SD_ST_BUSY	 BIT(8)

struct harbor_sd {
	void __iomem *base;
	struct mmc_host *mmc;
	unsigned int clk_freq;
	int irq;
};

static void harbor_sd_set_ios(struct mmc_host *mmc, struct mmc_ios *ios)
{
	struct harbor_sd *hs = mmc_priv(mmc);

	if (ios->clock && hs->clk_freq) {
		u32 div = (hs->clk_freq / (2 * ios->clock)) - 1;
		writel(div, hs->base + HARBOR_SD_CLK_DIV);
	}

	if (ios->power_mode == MMC_POWER_ON)
		writel(1, hs->base + HARBOR_SD_CTRL);
	else if (ios->power_mode == MMC_POWER_OFF)
		writel(0, hs->base + HARBOR_SD_CTRL);
}

static int harbor_sd_wait_cmd(struct harbor_sd *hs)
{
	int timeout = 1000000;

	while (readl(hs->base + HARBOR_SD_STATUS) & HARBOR_SD_ST_BUSY) {
		if (--timeout == 0)
			return -ETIMEDOUT;
		cpu_relax();
	}
	return 0;
}

static void harbor_sd_request(struct mmc_host *mmc, struct mmc_request *mrq)
{
	struct harbor_sd *hs = mmc_priv(mmc);
	struct mmc_command *cmd = mrq->cmd;
	struct mmc_data *data = mrq->data;
	int ret;

	/* Set up data transfer if present */
	if (data) {
		writel(data->blksz, hs->base + HARBOR_SD_BLK_SIZE);
		writel(data->blocks, hs->base + HARBOR_SD_BLK_COUNT);
	}

	/* Send command */
	writel(cmd->arg, hs->base + HARBOR_SD_CMD_ARG);
	writel(cmd->opcode & 0x3F, hs->base + HARBOR_SD_CMD);

	ret = harbor_sd_wait_cmd(hs);
	if (ret) {
		cmd->error = ret;
		goto done;
	}

	/* Read response */
	if (cmd->flags & MMC_RSP_PRESENT) {
		cmd->resp[0] = readl(hs->base + HARBOR_SD_RESP0);
		if (cmd->flags & MMC_RSP_136) {
			cmd->resp[1] = readl(hs->base + HARBOR_SD_RESP1);
			cmd->resp[2] = readl(hs->base + HARBOR_SD_RESP2);
			cmd->resp[3] = readl(hs->base + HARBOR_SD_RESP3);
		}
	}

	/* Data transfer */
	if (data) {
		struct scatterlist *sg;
		int i, j;

		for_each_sg(data->sg, sg, data->sg_len, i)
		{
			u32 *buf = sg_virt(sg);
			int words = sg->length / 4;

			for (j = 0; j < words; j++) {
				if (data->flags & MMC_DATA_READ)
					buf[j] =
					    readl(hs->base + HARBOR_SD_DATA);
				else
					writel(buf[j],
					       hs->base + HARBOR_SD_DATA);
			}
		}
		data->bytes_xfered = data->blocks * data->blksz;
	}

done:
	mmc_request_done(mmc, mrq);
}

static int harbor_sd_get_cd(struct mmc_host *mmc)
{
	struct harbor_sd *hs = mmc_priv(mmc);

	return !!(readl(hs->base + HARBOR_SD_STATUS) &
		  HARBOR_SD_ST_CARD_DETECT);
}

static const struct mmc_host_ops harbor_sd_ops = {
    .request = harbor_sd_request,
    .set_ios = harbor_sd_set_ios,
    .get_cd = harbor_sd_get_cd,
};

static int harbor_sd_probe(struct platform_device *pdev)
{
	struct harbor_sd *hs;
	struct mmc_host *mmc;
	struct clk *clk;
	u32 max_freq = 50000000;
	u32 bus_width = 4;

	mmc = mmc_alloc_host(sizeof(*hs), &pdev->dev);
	if (!mmc)
		return -ENOMEM;

	hs = mmc_priv(mmc);
	hs->mmc = mmc;

	hs->base = devm_platform_ioremap_resource(pdev, 0);
	if (IS_ERR(hs->base)) {
		mmc_free_host(mmc);
		return PTR_ERR(hs->base);
	}

	clk = devm_clk_get_optional_enabled(&pdev->dev, NULL);
	if (IS_ERR(clk)) {
		mmc_free_host(mmc);
		return PTR_ERR(clk);
	}
	hs->clk_freq = clk ? clk_get_rate(clk) : max_freq;

	of_property_read_u32(pdev->dev.of_node, "max-frequency", &max_freq);
	of_property_read_u32(pdev->dev.of_node, "bus-width", &bus_width);

	mmc->ops = &harbor_sd_ops;
	mmc->f_min = 400000;
	mmc->f_max = max_freq;
	mmc->ocr_avail = MMC_VDD_32_33 | MMC_VDD_33_34;
	mmc->caps = MMC_CAP_SD_HIGHSPEED | MMC_CAP_MMC_HIGHSPEED;

	if (bus_width >= 4)
		mmc->caps |= MMC_CAP_4_BIT_DATA;
	if (bus_width >= 8)
		mmc->caps |= MMC_CAP_8_BIT_DATA;

	mmc->max_blk_size = 4096;
	mmc->max_blk_count = 65535;
	mmc->max_segs = 1;
	mmc->max_seg_size = mmc->max_blk_size * mmc->max_blk_count;
	mmc->max_req_size = mmc->max_seg_size;

	platform_set_drvdata(pdev, hs);

	return mmc_add_host(mmc);
}

static void harbor_sd_remove(struct platform_device *pdev)
{
	struct harbor_sd *hs = platform_get_drvdata(pdev);

	mmc_remove_host(hs->mmc);
	mmc_free_host(hs->mmc);
}

static const struct of_device_id harbor_sd_of_match[] = {
    {.compatible = "harbor,sdhci"}, {.compatible = "harbor,sdhci-emmc"}, {}};
MODULE_DEVICE_TABLE(of, harbor_sd_of_match);

static struct platform_driver harbor_sd_driver = {
    .probe = harbor_sd_probe,
    .remove = harbor_sd_remove,
    .driver =
	{
	    .name = "harbor-sdhci",
	    .of_match_table = harbor_sd_of_match,
	},
};
module_platform_driver(harbor_sd_driver);

MODULE_AUTHOR("Midstall Software");
MODULE_DESCRIPTION("Harbor SD/SDIO/eMMC host controller driver");
MODULE_LICENSE("GPL");
