---
name: analysis-run
description: Use for every coding TASK from the coordinator — write a small Python script, run it, verify the output, and return numbers plus an optional chart.
---

# Analysis run

1. Copy the input data from the TASK into the script literally (a dict or a pandas DataFrame). Never fetch data from the internet.
2. Write the script to `./out/t<N>.py` and run it (`python out/t<N>.py`).
   - Use `import matplotlib; matplotlib.use("Agg")` before pyplot.
   - Save charts with `plt.savefig("out/t<N>.png", dpi=150, bbox_inches="tight")`.
3. Read the real output. If there is an error, fix and re-run — **max 3 attempts**.
4. Sanity-check: units, signs, totals add up, chart axes labelled with units.
5. Reply in the RESULT format from SOUL.md. Attach the chart as `MEDIA:<absolute path>` (use `realpath out/t<N>.png`).

Allowed libraries: standard library, numpy, pandas, matplotlib.
