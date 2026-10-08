"""Load patterns in PJM metered data, July to October 2025.

Reproduces the weekly load heatmap and daily load profile for the RTO
(whole PJM footprint) from the metered load file included in this repository.

    pip install pandas matplotlib
    python python/load_patterns.py
"""

from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data" / "hour_load_metered.csv"
OUT = ROOT / "assets"
DAYS = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]


def load_rto() -> pd.DataFrame:
    df = pd.read_csv(DATA)
    df = df[(df["zone"] == "RTO") & (df["load_area"] == "RTO")].copy()
    df["time"] = pd.to_datetime(df["datetime_beginning_ept"], format="%m/%d/%Y %I:%M:%S %p")
    df["gw"] = df["mw"] / 1000
    return df.sort_values("time")


def weekly_heatmap(df: pd.DataFrame) -> pd.DataFrame:
    grid = (
        df.assign(day=df["time"].dt.day_name(), hour=df["time"].dt.hour)
        .pivot_table(index="hour", columns="day", values="gw", aggfunc="mean")[DAYS]
    )
    fig, ax = plt.subplots(figsize=(8, 6.5))
    im = ax.imshow(grid.values, aspect="auto", cmap="inferno")
    ax.set_xticks(range(7), [d[:3] for d in DAYS])
    ax.set_yticks(range(0, 24, 3), [f"{h:02d}:00" for h in range(0, 24, 3)])
    ax.set_ylabel("hour of day (Eastern)")
    ax.set_title("Average PJM load by weekday and hour, Jul to Oct 2025", loc="left", fontweight="bold")
    fig.colorbar(im, ax=ax, label="average load (GW)", shrink=0.85)
    fig.tight_layout()
    fig.savefig(OUT / "weekly_load_heatmap.png", dpi=160)
    plt.close(fig)
    return grid


def daily_profile(df: pd.DataFrame) -> pd.Series:
    daily = df.set_index("time")["gw"].resample("D").agg(["mean", "max"])
    top = daily["max"].nlargest(10)
    fig, ax = plt.subplots(figsize=(10, 3.8))
    ax.fill_between(daily.index, daily["mean"], color="#9ecae1", alpha=0.6, label="daily average")
    ax.plot(daily.index, daily["max"], color="#08519c", lw=1.4, label="daily peak")
    ax.scatter(top.index, top.values, color="#e6550d", zorder=3, s=22, label="10 highest peak days")
    ax.set_ylabel("load (GW)")
    ax.set_ylim(bottom=float(np.floor(daily["mean"].min() / 10) * 10 - 10))
    ax.set_title("PJM RTO load, July to October 2025", loc="left", fontweight="bold")
    ax.legend(frameon=False, ncol=3, loc="upper right")
    ax.spines[["top", "right"]].set_visible(False)
    fig.tight_layout()
    fig.savefig(OUT / "daily_load_profile.png", dpi=160)
    plt.close(fig)
    return top


if __name__ == "__main__":
    OUT.mkdir(exist_ok=True)
    rto = load_rto()
    grid = weekly_heatmap(rto)
    top = daily_profile(rto)
    peak_hour, peak_day = np.unravel_index(np.nanargmax(grid.values), grid.shape)
    print(f"{len(rto):,} hourly RTO observations, {rto['time'].min():%Y-%m-%d} to {rto['time'].max():%Y-%m-%d}")
    print(f"Highest average load: {DAYS[peak_day]} at {peak_hour:02d}:00 ({grid.values.max():.1f} GW)")
    print("Top 10 peak days:", ", ".join(f"{d:%a %b %d}" for d in top.index))
