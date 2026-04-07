import chromadb
import logging

# Setup logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

def connect_to_docker_chroma():
    try:
        # 1. Connect to the Docker container
        # On Mac, Docker Desktop maps 'localhost' to the container's exposed port
        client = chromadb.HttpClient(host='localhost', port=8000)
        
        # Verify connection with a heartbeat
        logger.info(f"Heartbeat: {client.heartbeat()} - Connection Successful!")

        # 2. Create or Get Collection
        collection = client.get_or_create_collection(name="docker_collection")
        logger.info("Accessing 'docker_collection'...")

        # 3. Add sample data
        collection.upsert(
            documents=["Chroma is running in Docker!", "I love my Mac setup"],
            metadatas=[{"env": "docker"}, {"env": "macos"}],
            ids=["id_1", "id_2"]
        )
        logger.info("Upserted 2 documents.")

        # 4. Read and Log all collections
        collections = client.list_collections()
        logger.info(f"Total collections found: {len(collections)}")
        
        for col in collections:
            # We use col.count() to show how many items are inside
            logger.info(f" -> [Collection] Name: {col.name} | Items: {col.count()}")

    except Exception as e:
        logger.error(f"Could not connect to ChromaDB. Is the Docker container running? Error: {e}")

if __name__ == "__main__":
    connect_to_docker_chroma()