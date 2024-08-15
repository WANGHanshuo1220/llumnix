# When recieve ctrl+c from user
cleanup() {
    echo "Stopping ray server"
    ray stop
    echo "Ray server stopped."
    exit 0
}

# Trace ctrl+c command
trap cleanup SIGINT

# Configure on all nodes.
HEAD_NODE_IP_ADDRESS=$(ifconfig | grep 'inet ' | awk '{print $2}' | head -n 1)
export HEAD_NODE_IP=$HEAD_NODE_IP_ADDRESS

# Configure on head node.
export HEAD_NODE=1

# Run llumnix api server
# Get GPU count
gpu_count=$(nvidia-smi --query-gpu=name --format=csv,noheader | wc -l)
echo "Detected GPUs: $gpu_count"

HOST="localhost"
PORT="8003"
INITIAL_INSTANCES=$gpu_count
MODEL_PATH="/root/models/facebook/opt-6.7b/"
DRAFT_MODEL_PATH="/root/models/facebook/opt-125m/"
MAX_MODEL_LEN=2048

python -m llumnix.entrypoints.vllm.api_server \
    --host $HOST \
    --port $PORT \
    --initial-instances $INITIAL_INSTANCES \
    --launch-ray-cluster \
    --model $MODEL_PATH \
    --engine-use-ray \
    --worker-use-ray \
    --speculative-model $DRAFT_MODEL_PATH \
    --num-speculative-tokens 5 \
    --use-v2-block-manager \
    --max-model-len $MAX_MODEL_LEN &
server_pid=$!

echo "Run llumnix api server successfully"

# Run llumnix server benchmark
cd benchmark
NUM_PROMPTS=10
QPS=0.1
FILE="/root/vllm/ShareGPT_V3_unfiltered_cleaned_split.json"

# Check if dataset exists
if [ -e "$FILE" ]; then
    echo "$FILE already exist"
else
    echo "$FILE does not exist, downloading it ..."
    wget https://huggingface.co/datasets/anon8231489123/ShareGPT_Vicuna_unfiltered/resolve/main/ShareGPT_V3_unfiltered_cleaned_split.json
    echo "$FILE download done."
fi

# Wait 180 seconds for server to initialize...
timeout 180 bash -c 'until curl -s localhost:8003/is_ready > /dev/null; do sleep 1; done' || exit 1
echo "Server ready."
# python benchmark_serving.py \
#     --ip_ports $HOST:$PORT \
#     --tokenizer $MODEL_PATH \
#     --random_prompt_count $NUM_PROMPTS \
#     --dataset_type "sharegpt" \
#     --dataset_path $FILE\
#     --qps $QPS \
#     --distribution "poisson" \
#     --log_latencies \
#     --fail_on_response_failure

kill $server_pid

echo "Stopping ray server"
ray stop
echo "Ray server stopped."

