# Configure on all nodes.
HEAD_NODE_IP_ADDRESS=$(ifconfig | grep 'inet ' | awk '{print $2}' | head -n 1)
export HEAD_NODE_IP=$HEAD_NODE_IP_ADDRESS

# Configure on head node.
export HEAD_NODE=1

# Run llumnix api server
HOST="localhost"
PORT="8003"
INITIAL_INSTANCES=1
MODEL_PATH="/root/models/facebook/opt-6.7b/"
MAX_MODEL_LEN=2048

python -m llumnix.entrypoints.vllm.api_server \
    --host $HOST \
    --port $PORT \
    --initial-instances $INITIAL_INSTANCES \
    --launch-ray-cluster \
    --model $MODEL_PATH \
    --engine-use-ray \
    --worker-use-ray \
    --max-model-len $MAX_MODEL_LEN

echo "Run llumnix api server successfully"

echo "Stopping ray server"
ray stop
echo "Ray server stopped."