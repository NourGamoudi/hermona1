import json
import numpy as np

with open('model_dump.json', 'r') as f:
    dump = json.load(f)

thresholds = {
    'LH': [],
    'estradiol': [],
    'progesterone': [],
    'testosterone': []
}

def parse_tree(node):
    if 'split_feature' in node:
        feat_idx = node['split_feature']
        feat_name = dump['feature_names'][feat_idx]
        if feat_name in thresholds:
            thresholds[feat_name].append(node['threshold'])
        if 'left_child' in node:
            parse_tree(node['left_child'])
        if 'right_child' in node:
            parse_tree(node['right_child'])

for tree_info in dump['tree_info']:
    parse_tree(tree_info['tree_structure'])

for feat, threshs in thresholds.items():
    if len(threshs) == 0:
        print(f"{feat}: No splits")
    else:
        print(f"{feat}: Splits count = {len(threshs)}, Min = {np.min(threshs):.4f}, Max = {np.max(threshs):.4f}, Mean = {np.mean(threshs):.4f}, Median = {np.median(threshs):.4f}")
