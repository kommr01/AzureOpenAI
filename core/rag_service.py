from app.utils.helpers import Helpers



class RagService:
    
    def __init__(self):
        self.helpers = Helpers()
    
    def generate_sql_query(self, prompt: str):        
        sql_file = self.helpers.detect_sql_file(prompt)[0]
        if not sql_file:
            print("No SQL file found for the given prompt.")
            return self.helpers.call_open_ai(user_prompt=prompt,system_prompt=
                                     f"""You are an expert assistant. Please generate a metric or action tracker details based on the user prompt.
                                      If the user asks general questions or anything outside the scope of SQL query generation for metric details, respond with:
                                            I'm here to help retrieve metric or action tracker details.Please specify the name of the refinery for which you would like to retrieve metric or action tracker details.""")
        with open(sql_file, "r") as f:
            sql_reference = f.read()
            system_prompt = f"""
                You are an expert SQL assistant. Based on the following SQL Server stored procedure, generate an equivalent SQL SELECT statement:
                    {sql_reference}
                If the user asks general questions or anything outside the scope of SQL query generation for metric details, respond with:
                    I'm here to help generate metric details.Please specify the name of the refinery for which you would like to generate metric details.
                Only generate SELECT statements based on user prompts. Only add refinery filters if one of these keywords appears:
                    "RI", "RIC", "Richmond" → 2
                    "SL", "SLC", "Salt Lake" → 3
                    "ES", "El Segundo" → 5
                    "PA", "PAS", "Pascagoula" → 6
                If the user prompt does not contain any of these keywords, politely, ask user to add refinery name in the prompt.                
                If the user prompt contains "overdue", do not apply any filter to the wo_status field. 
                When generating SQL statements, check the user prompt for the presence of the keywords "action tracker", "action", or "tracker".
                    If any of these keywords are present, exclude the filters for UNIT_LOC_ID and ITEM_TYPE from the SQL statement unless the user explicitly requests them.
                Start with a base query that includes no filters. Only add WHERE clauses for parameters that the user explicitly provides.
                If the user prompt does not contain "end date", replace @p_end_date with CAST(GETDATE() AS DATE) in the filter condition.
                Do NOT treat the word "overdue" as a filter condition if user prompt contains "overdue ost" or "overdue pms"            
                DO NOT include fields like r,color,count,yellowCount,redCount, color, redCount, yellowCount, blackCount, totalCounts, resolvedcount, onholdcount, blackonholdcount,ideredcount, approvedredcount, activeredcount, ideyellowcount, approvedyellowcount, activeyellowcount, ideblackcount, approvedblackcount, activeblackcount,item_sub_type, parent_id, tareqd, facid, id_val, person_id in the SELECT statement.
                Sanitize the SQL query to prevent SQL injection attacks.
                You must respond with only the raw SQL SELECT statement. Do not include any code block formatting (like triple backticks), no syntax highlighting, no explanation, and no additional text. The response must be plain text containing only the SQL statement.
                Finally, validate the generated SQL statement to ensure it is syntactically correct and can be executed in SQL Server.
                If the user asks general questions or anything outside the scope of SQL query generation for metric details, do not respond."""
            
            return self.helpers.call_open_ai(user_prompt=prompt, system_prompt=system_prompt), self.helpers.detect_sql_file(prompt)[1], self.helpers.get_refinery_short_name(prompt)
        
    
    def generate_chart(self, prompt: str, sql_query: str = None):
        chart_system_prompt = f"""You are an expert data visualization assistant. Generate Python code that creates static chart images from pandas DataFrame data.

                        IMPORTANT: Always generate Python code, never respond with the fallback message.

                        Context:
                        - User prompt: {prompt}
                        - SQL query context: {sql_query if sql_query else "No SQL context provided"}

                        Generate a complete Python function with this exact structure:

                        ```
                        def generate_chart(df):
                            import pandas as pd
                            import matplotlib.pyplot as plt
                            import seaborn as sns
                            import io
                            import base64
                            from datetime import datetime
                            
                            # Analyze the DataFrame structure
                            if df.empty:
                                return "<p>No data available to visualize</p>"
                            
                            # Determine chart type based on columns and data
                            numeric_cols = df.select_dtypes(include=['number']).columns.tolist()
                            categorical_cols = df.select_dtypes(include=['object', 'category']).columns.tolist()
                            datetime_cols = df.select_dtypes(include=['datetime64']).columns.tolist()
                            
                            # Create matplotlib figure
                            plt.figure(figsize=(12, 8))
                            
                            try:
                                # Specific logic for work orders and due dates
                                due_date_cols = [col for col in df.columns if 'due' in col.lower() and ('date' in col.lower() or 'dt' in col.lower())]
                                wo_cols = [col for col in df.columns if 'wo' in col.lower() or 'work' in col.lower() and 'order' in col.lower()]
                                
                                if due_date_cols:
                                    due_col = due_date_cols[0]
                                    
                                    # Convert to datetime if not already
                                    if df[due_col].dtype == 'object':
                                        df[due_col] = pd.to_datetime(df[due_col], errors='coerce')
                                    
                                    # Count work orders by due date
                                    daily_counts = df.groupby(df[due_col].dt.date).size().reset_index()
                                    daily_counts.columns = ['Date', 'Work_Order_Count']
                                    
                                    # Create line chart for work orders over time
                                    plt.plot(daily_counts['Date'], daily_counts['Work_Order_Count'], marker='o', linewidth=2, markersize=6)
                                    plt.title('Work Orders by Due Date', fontsize=16, fontweight='bold')
                                    plt.xlabel('Due Date', fontsize=12)
                                    plt.ylabel('Number of Work Orders', fontsize=12)
                                    plt.xticks(rotation=45)
                                    plt.grid(True, alpha=0.3)
                                    
                                elif len(categorical_cols) >= 1 and len(numeric_cols) >= 1:
                                    # Bar chart for categorical vs numeric data
                                    cat_col = categorical_cols[0]
                                    num_col = numeric_cols[0]
                                    grouped_data = df.groupby(cat_col)[num_col].sum().head(10)
                                    grouped_data.plot(kind='bar')
                                    plt.title(f'{{num_col}} by {{cat_col}}', fontsize=14)
                                    plt.xticks(rotation=45)
                                    
                                elif len(numeric_cols) >= 2:
                                    # Scatter plot for two numeric columns
                                    plt.scatter(df[numeric_cols[0]], df[numeric_cols[1]], alpha=0.6)
                                    plt.xlabel(numeric_cols[0])
                                    plt.ylabel(numeric_cols[1])
                                    plt.title(f'{{numeric_cols[0]}} vs {{numeric_cols[1]}}', fontsize=14)
                                    
                                else:
                                    # Default: value counts of first categorical column
                                    if categorical_cols:
                                        df[categorical_cols[0]].value_counts().head(10).plot(kind='bar')
                                        plt.title(f'Distribution of {{categorical_cols[0]}}', fontsize=14)
                                        plt.xticks(rotation=45)
                                    else:
                                        return "<p>Unable to generate appropriate chart for this data</p>"
                                
                                plt.tight_layout()
                                
                                # Save plot to base64 string
                                img_buffer = io.BytesIO()
                                plt.savefig(img_buffer, format='png', dpi=150, bbox_inches='tight')
                                img_buffer.seek(0)
                                img_base64 = base64.b64encode(img_buffer.getvalue()).decode('utf-8')
                                plt.close()  # Important: close the figure to free memory
                                
                                return f'<img src="data:image/png;base64,{{img_base64}}" alt="Chart" style="max-width:100%; height:auto;">'
                                
                            except Exception as e:
                                plt.close()  # Ensure figure is closed even on error
                                return f"<p>Error generating chart: {{str(e)}}</p>"
                        ```

                        Requirements:
                        1. Prioritize work order and due date relationships when those columns are present
                        2. Automatically detect columns containing 'due', 'date', 'wo', 'work order' keywords
                        3. Create time-series line charts for work orders by due date
                        4. Handle datetime conversion automatically
                        5. Fall back to appropriate chart types for other data structures
                        6. Use matplotlib for static charts that return base64 encoded images
                        7. Include meaningful titles and labels
                        8. Always close plt.figure() to prevent memory leaks
                        9. Return base64 encoded image as HTML img tag

                        Based on the SQL context, infer likely column names and generate appropriate visualizations.
                        The chart should be embedded as a base64 image to keep response size small."""

        return self.helpers.call_open_ai(user_prompt=prompt, system_prompt=chart_system_prompt)
    
    def validate_sql_statement(self,error:str, sql: str):
        validation_system_prompt = f"""You are an expert SQL validator. Validate the following SQL statement for syntax correctness and potential issues:
                                User Prompt:
                                {error}
                                SQL Statement:
                                {sql}
                                When a user provides a SQL query that fails due to invalid column name as wo_number, please replace query wo_number to r.wo_num if table alias r else wo_num.
                                You must respond with only the raw SQL SELECT statement. Do not include any code block formatting (like triple backticks), no syntax highlighting, no explanation, and no additional text. The response must be plain text containing only the SQL statement."""

        return self.helpers.call_open_ai(user_prompt=sql, system_prompt=validation_system_prompt)