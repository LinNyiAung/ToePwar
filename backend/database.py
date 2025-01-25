from pymongo import MongoClient

# Replace with your MongoDB Atlas connection string
MONGO_URI = "mongodb+srv://linnyiaung1794:POlwZWJXD3yBgscY@toepwar.dnfqh.mongodb.net/?retryWrites=true&w=majority&appName=toepwar"
client = MongoClient(MONGO_URI)
db = client["toepwar"]

# Collections
users_collection = db["users"]
transactions_collection = db["transactions"]
goals_collection = db["goals"]
admins_collection = db["admins"]
notifications_collection = db["notifications"]

# Send a ping to confirm a successful connection
try:
    client.admin.command('ping')
    print("Pinged your deployment. You successfully connected to MongoDB!")
except Exception as e:
    print(e)
