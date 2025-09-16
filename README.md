# FastAPI SQL Assistant

This project is a FastAPI application designed to assist with SQL queries and interactions with an Azure SQL Database. It leverages the OpenAI API to generate SQL queries based on user prompts.

## Project Structure

```
fastapi-sql-assistant
├── app
│   ├── main.py               # Entry point of the FastAPI application
│   ├── api
│   │   └── endpoints.py      # API endpoints for handling requests
│   ├── core
│   │   ├── config.py         # Configuration settings for the application
│   │   └── openai_client.py   # Logic for interacting with the OpenAI API
│   ├── db
│   │   ├── connection.py      # Database connection management
│   │   └── queries.py         # Reusable database query functions
│   └── utils
│       └── helpers.py         # Utility functions for data validation and formatting
├── requirements.txt           # Project dependencies
└── README.md                  # Project documentation
```

## Setup Instructions

1. **Clone the repository:**
   ```
   git clone <repository-url>
   cd fastapi-sql-assistant
   ```

2. **Create a virtual environment:**
   ```
   python -m venv venv
   source venv/bin/activate  # On Windows use `venv\Scripts\activate`
   ```

3. **Install dependencies:**
   ```
   pip install -r requirements.txt
   ```

4. **Run the application:**
   ```
   uvicorn app.main:app --reload
   ```

## Usage

- Access the API documentation at `http://localhost:8000/docs` after running the application.
- Use the endpoints defined in `app/api/endpoints.py` to interact with the SQL Assistant.

## Contributing

Contributions are welcome! Please open an issue or submit a pull request for any enhancements or bug fixes.

## License

This project is licensed under the MIT License. See the LICENSE file for more details.