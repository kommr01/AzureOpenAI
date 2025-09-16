from fastapi import APIRouter, HTTPException
from app.db.queries import  run_query
from app.core.rag_service import RagService
from app.utils.helpers import Helpers
from io import StringIO


router = APIRouter()

rag = RagService()
helpers = Helpers()

@router.post("/chat/")
async def chat(user_prompt: str):
    output = rag.generate_sql_query(user_prompt)
    query = output[0]
   
    if helpers.validate_sql_statement(query).lower() == "true":  
        data = run_query(query)
        if isinstance(data, Exception):
            value = rag.validate_sql_statement(data,query)
            print(f"SQL query validation result: {value}")
            return {"output": "Unable to retrieve data, please try again!"}
        else:
            float_cols = data.select_dtypes(include=['float']).columns
            for col in float_cols:
                data[col] = data[col].fillna(0).astype('Int64')
            
            result = data.head(20)
            styled_df = result.style.set_table_attributes('style="max-width:300px; max-height:500px; overflow-y:auto;overflow-x:auto;border-collapse: collapse;"')
            styled_df = styled_df.set_properties(**{
                'word-wrap': 'break-word',
                'max-width': '100px',
                'white-space': 'normal',
                'border': '1px solid #dddddd',  # Add borders to all cells
                'padding': '8px',
                'max-height': '100px',
                'white-space': 'nowrap',
                'overflow': 'hidden',
                'text-overflow': 'ellipsis',
            })
            styled_df = styled_df.set_table_styles([
                {'selector': 'thead th', 
                'props': [('background-color', '#0b2d71'), 
                        ('color', 'white'),
                        ('border', '1px solid #dddddd')]},
            ])
            def add_tooltip_to_long_cells(val):
                if isinstance(val, str) and len(val) > 100:
                    return f'<span title="{val}" style="cursor:help;">{val}</span>'
                return val

            styled_df = styled_df.format(add_tooltip_to_long_cells)
            # Write to file
            # styled_df.to_html('output.html', index=False,  header=True)
            writeToBuffer = StringIO()
            # styled_df.to_html(buf=writeToBuffer, index=False, header=True)
            styled_df = styled_df.hide(axis="index")
            styled_df.to_html(buf=writeToBuffer, header=True)
            method = rag.generate_chart(query, query)
            
            # Clean the method string to remove markdown formatting
            chart_html = generate_chart_html(method,data)
            html = html_content(styled_df,chart_html, output[1], output[2], len(result))
            return {"output":html}
       
    else:
        return {"output":output}
    
def html_content(df: any,chart_html, metric_name: str, fac_short_name:str, count: int) -> str:
    
  return f"""<html>
        <head>
            <style>
                .metric-label {{
                    font-weight: bold;
                    margin-top: 20px;
                }}
                .metric-table {{
                    width: 400px;
                    border-collapse: collapse;
                    
                }}

            </style>
        </head>
        <body>            
            <div class="metric-label"> {fac_short_name} - {metric_name} - {count}</div>
            <br>
            <div class="metric-table">
            { df.to_html(index=False) }
            </div>
            <div class="chart-container">
                {chart_html}
            </div>
        </body>
        </html>"""

def generate_chart_html(method:any,df:any):
    if method.startswith('```python'):
            method = method.replace('```python', '').replace('```', '').strip()
    elif method.startswith('```'):
        method = method.replace('```', '').strip()
    if method.endswith('```'):
        method = method[:-3].strip()
    local_namespace = {}
    exec(method, globals(), local_namespace)

    # Now you can access the function
    try:
        generate_chart = local_namespace['generate_chart']
    except Exception as e:
        return f"<p>Error in generating chart: {str(e)}</p>"
        

    return generate_chart(df)
    