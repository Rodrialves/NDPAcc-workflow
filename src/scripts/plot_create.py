import pandas as pd
import numpy as np
import matplotlib.pyplot as plt


def read_multiblock_csv(path):
    """
    Reads a CSV where each block is prefixed by a line like:
      ,design_name,,,,
    followed by
      ,Frequency (MHz),Average Time…, …
    and data lines (also starting with a comma).
    Blocks are separated by blank or all-comma lines.
    Returns a single DataFrame with a 'Design' column and standardized column names.
    """
    with open(path, "r") as f:
        raw = f.readlines()

    blocks = []
    i = 0
    while i < len(raw):
        line = raw[i].strip()
        parts = line.split(",")
        if len(parts) > 1 and parts[0] == "" and parts[1] and all(p == "" for p in parts[2:]):
            design = parts[1]
            i += 1
            while i < len(raw) and (raw[i].strip() == "" or set(raw[i].strip()) == {","}):
                i += 1
            header = raw[i].lstrip(",").strip()
            i += 1
            data_lines = []
            while i < len(raw):
                l = raw[i].strip()
                p = l.split(",")
                if len(p) > 1 and p[0] == "" and p[1] and all(x == "" for x in p[2:]):
                    break
                if l and set(l) != {","}:
                    data_lines.append(raw[i].lstrip(","))
                i += 1
            block_df = pd.read_csv(
                pd.io.common.StringIO(header + "\n" + "".join(data_lines)),
                sep="," , decimal="," )
            block_df["Design"] = design
            blocks.append(block_df)
        else:
            i += 1

    df = pd.concat(blocks, ignore_index=True)
    # Standardize column names
    rename_map = {
        "Average Time (seconds)": "Average Time (s)",
        "Stddev Time (seconds)": "Stddev Time (s)",
        "Average Power (W)": "Average Power (W)",
        "Stddev Power (W)": "Stddev Power (W)",
        "Frequency (MHz)": "Frequency (MHz)"
    }
    df.rename(columns=rename_map, inplace=True)
    # Convert numeric columns
    for col in ["Frequency (MHz)", "Average Time (s)", "Stddev Time (s)",
                "Average Power (W)", "Stddev Power (W)"]:
        df[col] = pd.to_numeric(df[col], errors="coerce")
    return df


def plot_small_multiples(df, val_col, std_col, ylabel, title, out_pdf):
    """
    Creates small multiple bar charts: one subplot per design.
    Bars have a width proportional to each design's frequency span.
    For time charts, uses full global scale across subplots.
    For power charts, tightens y-axis around data range.
    """
    designs = df["Design"].unique()
    n = len(designs)
    cols = 2
    rows = int(np.ceil(n/cols))

    # Precompute global y-limits for time
    if "Time" in val_col:
        all_y = df[val_col].dropna().values
        all_err = df[std_col].dropna().values
        global_ymin = (all_y - all_err).min()
        global_ymax = (all_y + all_err).max()
        margin = (global_ymax - global_ymin) * 0.1
        time_ylim = (global_ymin - margin, global_ymax + margin)
    else:
        time_ylim = None

    fig, axes = plt.subplots(rows, cols, figsize=(cols*6, rows*4), sharey=False)
    axes = axes.flatten()
    cmap = plt.get_cmap('tab10')

    for idx, (ax, design) in enumerate(zip(axes, designs)):
        color = cmap(idx % 10)
        sub = df[df["Design"] == design].dropna(subset=["Frequency (MHz)", val_col]).sort_values("Frequency (MHz)")
        x = sub["Frequency (MHz)"].values
        y = sub[val_col].values
        yerr = sub[std_col].values

        # compute bar width per design as 5% of its own span
        if len(x) > 1:
            span = x.max() - x.min()
            bar_width = span * 0.015
        else:
            bar_width = 1.0

        ax.bar(x, y, yerr=yerr, capsize=4, width=bar_width, color=color,
               edgecolor='black', zorder=2)

        # quadratic trendline fit
        if len(x) > 2:
            coeffs = np.polyfit(x, y, 2)
            x_line = np.linspace(x.min(), x.max(), 200)
            y_line = np.polyval(coeffs, x_line)
            ax.plot(x_line, y_line, linestyle='--', linewidth=2.5,
                    color='red', zorder=3)

        ax.set_title(design, loc='right')
        ax.set_xlabel("Frequency (MHz)")
        ax.set_ylabel(ylabel)
        ax.grid(axis="y", linestyle="--", alpha=0.5)

        if "Time" in val_col:
            # apply global time scale
            ax.set_ylim(time_ylim)
        else:
            # tighten y-axis for power charts
            ymin = np.min(y - yerr)
            ymax = np.max(y + yerr)
            margin_p = (ymax - ymin) * 0.1
            ax.set_ylim(ymin - margin_p, ymax + margin_p)

    # remove unused axes
    for ax in axes[n:]:
        fig.delaxes(ax)

    fig.suptitle(title)
    fig.tight_layout(rect=[0, 0.03, 1, 0.95])
    fig.savefig(out_pdf, format='pdf')
    plt.close(fig)

if __name__ == "__main__":
    csv_path = "flow_results_multiblock.csv"
    df = read_multiblock_csv(csv_path)

    plot_small_multiples(
        df,
        val_col="Average Time (s)",
        std_col="Stddev Time (s)",
        ylabel="Average Time (s)",
        title="Average Time Variation by Design and Frequency",
        out_pdf="small_multiples_time_variation.pdf"
    )

    plot_small_multiples(
        df,
        val_col="Average Power (W)",
        std_col="Stddev Power (W)",
        ylabel="Average Power (W)",
        title="Average Power Variation by Design and Frequency",
        out_pdf="small_multiples_power_variation.pdf"
    )

    print("Saved PDFs: small_multiples_time_variation.pdf, small_multiples_power_variation.pdf")









