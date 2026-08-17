ckpt_path=$1
eval_split_name=$2
#eval_path=/root/New/labels/honor/highlight_${eval_split_name}_release.jsonl
repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd)"
eval_path="${repo_root}/labels/honor/highlight_${eval_split_name}_release.jsonl"
#eval_path="${repo_root}/labels/ying/highlight_${eval_split_name}_release.jsonl"
#eval_path="${repo_root}/labels/dota2/highlight_${eval_split_name}_release.jsonl"
#eval_path="${repo_root}/labels/total/highlight_${eval_split_name}_release.jsonl"
echo ${ckpt_path}
echo ${eval_split_name}
echo ${eval_path}
PYTHONPATH=$PYTHONPATH:. python tr_detr/inference.py \
--resume ${ckpt_path} \
--eval_split_name ${eval_split_name} \
--eval_path ${eval_path} \
${@:3}
