from fastapi import FastAPI
from app.api.endpoints import router as api_router
from app.utils import helpers as utils
from fastapi.middleware.cors import CORSMiddleware

HTML_TEMPLATE = """
<!doctype html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>SQL Results</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 40px;
        }
        h2 {
            color: #333;
        }
        table {
            border-collapse: collapse;
            width: 100%;
        }
        th, td {
            border: 1px solid #999;
            padding: 8px 12px;
            text-align: left;
        }
        th {
            background-color: #f2f2f2;
        }
        tr:nth-child(even) {
            background-color: #fafafa;
        }
        h1{
          text-align: center;
          color: #4CAF50;}
    </style>
</head>
<body>
<h1>Assistant for Operational Excellence Reliability Intelligence</h1>
<br><br><br><br><br><br><br><br><br><br>
<form method="post" style="margin-bottom: 20px;">
  <label for="prompt" style="font-weight: bold; margin-right: 10px;">Prompt:</label>
 <input 
  type="text" 
 id="prompt" 
 name="prompt" 
 size="80" 
 value="{{ prompt|default('') }}" 
 style="padding: 8px; font-size: 14px; width: 60%;"
 >
 <input 
 type="submit" 
  value="Submit" 
 style="padding: 8px 16px; font-size: 14px; margin-left: 10px;"
 >
</form>
<br><br><br>

    <h2>Results</h2>
    {% if columns or rows %}
    <table>
        <tr>
            {% for col in columns %}
                <th>{{ col }}</th>
            {% endfor %}
        </tr>
        {% for row in rows %}
            <tr>
                {% for cell in row %}
                    <td>{{ cell }}</td>
                {% endfor %}
            </tr>
        {% endfor %}
    </table>
    {% else %}
    {{output|safe}}
    {% endif %}
    
</body>
</html>

"""


fastapi_app = FastAPI()

origins = [
    "https://localhost:44300"# React dev server
]

fastapi_app.add_middleware(
    CORSMiddleware,
    allow_origins=origins, # Allows specific origins
    allow_credentials=True,
    allow_methods=["*"], # Allows all HTTP methods
    allow_headers=["*"], # Allows all headers
)

fastapi_app.include_router(api_router)
# fastapi_app.mount("/home", WSGIMiddleware(flask_app))


# if __name__ == "__main__":
#     import uvicorn
#     uvicorn.run(fastapi_app, host="0.0.0.0", port=8000)