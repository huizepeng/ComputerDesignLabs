#!/usr/bin/env python3
"""Generate figures for Lab-5 report."""

import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
import networkx as nx
import os

FIG_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "figures")
os.makedirs(FIG_DIR, exist_ok=True)

# ===== Figure 1: Module Hierarchy Diagram =====
def fig_module_hierarchy():
    G = nx.DiGraph()
    G.add_edges_from([
        ("board_number_demo\n(Top)", "debounce"),
        ("board_number_demo\n(Top)", "sort_8_nibbles"),
        ("board_number_demo\n(Top)", "scan_7seg"),
        ("scan_7seg", "hex_to_7seg"),
    ])
    pos = nx.spring_layout(G, seed=42)
    fig, ax = plt.subplots(figsize=(8, 5))
    nx.draw_networkx_nodes(G, pos, node_color="lightblue", node_size=2500, ax=ax)
    nx.draw_networkx_edges(G, pos, edge_color="gray", arrows=True, arrowsize=20, ax=ax)
    nx.draw_networkx_labels(G, pos, font_size=9, ax=ax)
    ax.set_title("Module Hierarchy of board_number_demo")
    ax.axis("off")
    fig.savefig(os.path.join(FIG_DIR, "module_hierarchy.png"), dpi=150, bbox_inches="tight")
    plt.close(fig)
    print("  [+] module_hierarchy.png")

# ===== Figure 2: Odd-Even Transposition Sort Network =====
def fig_sort_network():
    fig, axes = plt.subplots(1, 2, figsize=(14, 5))

    # Left: sorting stages
    ax = axes[0]
    stages = [
        ("Stage 0\n(even)", [(0,1),(2,3),(4,5),(6,7)]),
        ("Stage 1\n(odd)",  [(1,2),(3,4),(5,6)]),
        ("Stage 2\n(even)", [(0,1),(2,3),(4,5),(6,7)]),
        ("Stage 3\n(odd)",  [(1,2),(3,4),(5,6)]),
        ("Stage 4\n(even)", [(0,1),(2,3),(4,5),(6,7)]),
        ("Stage 5\n(odd)",  [(1,2),(3,4),(5,6)]),
        ("Stage 6\n(even)", [(0,1),(2,3),(4,5),(6,7)]),
        ("Stage 7\n(odd)",  [(1,2),(3,4),(5,6)]),
    ]
    for si, (label, pairs) in enumerate(stages):
        y = 7 - si
        for i in range(8):
            ax.plot([i], [y], 'ko', markersize=6)
        for a, b in pairs:
            ax.plot([a, b], [y, y], 'r-', linewidth=1.5)
            ax.plot([a, a, b, b], [y, y+0.3, y+0.3, y], 'g-', linewidth=0.8, alpha=0.5)
        ax.text(-1.2, y, label, fontsize=8, va='center')
    ax.set_xlim(-1.8, 8)
    ax.set_ylim(-1, 9)
    ax.set_xticks(range(8))
    ax.set_xticklabels([f"pos {i}" for i in range(8)], fontsize=7)
    ax.set_yticks([])
    ax.set_title("Odd-Even Transposition Sort (8 Stages)")

    # Right: example
    ax2 = axes[1]
    digits = [0, 2, 1, 8, 1, 0, 2, 4]
    sorted_digits = sorted(digits)
    colors_in = ['#FF6B6B' if i != j else '#51CF66' for i, j in zip(digits, sorted_digits)]
    colors_out = ['#51CF66'] * 8
    x = range(8)
    ax2.bar([xi - 0.15 for xi in x], digits, width=0.3, color=colors_in, label='Before sort')
    ax2.bar([xi + 0.15 for xi in x], sorted_digits, width=0.3, color=colors_out, label='After sort', alpha=0.8)
    for i, (d, s) in enumerate(zip(digits, sorted_digits)):
        ax2.text(i - 0.15, d + 0.2, str(d), ha='center', fontsize=8, fontweight='bold')
        ax2.text(i + 0.15, s + 0.2, str(s), ha='center', fontsize=8, fontweight='bold')
    ax2.set_xticks(x)
    ax2.set_xticklabels([f'd{i}' for i in range(8)])
    ax2.set_ylabel('BCD digit value')
    ax2.set_title("0x02181024 -> 0x00112248")
    ax2.legend(fontsize=7)
    ax2.set_ylim(0, 10)

    fig.tight_layout()
    fig.savefig(os.path.join(FIG_DIR, "sort_network.png"), dpi=150, bbox_inches="tight")
    plt.close(fig)
    print("  [+] sort_network.png")

# ===== Figure 3: 7-Segment Display Mapping =====
def fig_7seg_mapping():
    fig, ax = plt.subplots(figsize=(10, 4))

    seg_map = {
        '0': 0xC0, '1': 0xF9, '2': 0xA4, '3': 0xB0,
        '4': 0x99, '5': 0x92, '6': 0x82, '7': 0xF8,
        '8': 0x80, '9': 0x90, 'A': 0x88, 'B': 0x83,
        'C': 0xC6, 'D': 0xA1, 'E': 0x86, 'F': 0x8E,
    }
    chars = list(seg_map.keys())
    values = list(seg_map.values())

    ax.bar(chars, values, color='steelblue', edgecolor='navy')
    for i, (c, v) in enumerate(zip(chars, values)):
        ax.text(i, v + 3, f'0x{v:02X}', ha='center', fontsize=7, rotation=90)

    ax.set_xlabel('Hex Digit')
    ax.set_ylabel('Segment Code (common anode)')
    ax.set_title('Hex to 7-Segment Decoder Mapping')
    fig.tight_layout()
    fig.savefig(os.path.join(FIG_DIR, "hex_to_7seg_map.png"), dpi=150, bbox_inches="tight")
    plt.close(fig)
    print("  [+] hex_to_7seg_map.png")

# ===== Figure 4: Experiment Flowchart =====
def fig_flowchart():
    G = nx.DiGraph()
    steps = [
        "Requirements\nAnalysis",
        "Code\nImplementation",
        "Simulation\n(iverilog)",
        "Vivado\nProject",
        "Synthesis",
        "Implementation",
        "Bitstream\nGeneration",
        "Board\nProgramming",
        "Board\nVerification",
        "Report\nWriting",
    ]
    for i in range(len(steps) - 1):
        G.add_edge(steps[i], steps[i+1])

    pos = {}
    for i, s in enumerate(steps):
        pos[s] = (0, -i * 0.8)

    fig, ax = plt.subplots(figsize=(6, 9))
    nx.draw_networkx_nodes(G, pos, node_color='lightgreen', node_shape='s',
                           node_size=3500, edgecolors='darkgreen', ax=ax)
    nx.draw_networkx_edges(G, pos, edge_color='gray', arrows=True,
                           arrowsize=20, connectionstyle='arc3,rad=0', ax=ax)
    nx.draw_networkx_labels(G, pos, font_size=8, ax=ax)
    ax.set_title('Experiment Workflow')
    ax.axis('off')
    fig.savefig(os.path.join(FIG_DIR, "experiment_flowchart.png"), dpi=150, bbox_inches="tight")
    plt.close(fig)
    print("  [+] experiment_flowchart.png")

# ===== Figure 5: Scan Timing Diagram (synthetic) =====
def fig_scan_timing():
    fig, ax = plt.subplots(figsize=(10, 5))

    import numpy as np
    t = np.arange(0, 40, 0.1)
    digit_sel = (t // 4).astype(int) % 8
    disp_an = [0xFE, 0xFD, 0xFB, 0xF7, 0xEF, 0xDF, 0xBF, 0x7F]

    ax.step(t, digit_sel, where='post', linewidth=2, color='steelblue')
    ax.set_xlabel('Time (scan cycles)')
    ax.set_ylabel('digit_sel')
    ax.set_yticks(range(8))
    ax.set_yticklabels([f'{i}\n(AN=0x{disp_an[i]:02X})' for i in range(8)], fontsize=7)
    ax.set_title('7-Segment Dynamic Scan Timing')
    ax.grid(True, alpha=0.3)
    fig.tight_layout()
    fig.savefig(os.path.join(FIG_DIR, "scan_timing.png"), dpi=150, bbox_inches="tight")
    plt.close(fig)
    print("  [+] scan_timing.png")


if __name__ == "__main__":
    print("[INFO] Generating report figures...")
    fig_module_hierarchy()
    fig_sort_network()
    fig_7seg_mapping()
    fig_flowchart()
    fig_scan_timing()
    print(f"[DONE] Figures saved to {FIG_DIR}")
