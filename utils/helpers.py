from dotenv import load_dotenv
from azure.identity import  ClientSecretCredential, get_bearer_token_provider
import os
from openai import AzureOpenAI as AzureOpenAIClient


load_dotenv()

class Helpers:

    def get_access_token(self):
        try:
            tenant_id = os.getenv("AZURE_TENANT_ID")
            client_id = os.getenv("AZURE_CLIENT_ID")
            client_secret = os.getenv("AZURE_CLIENT_SECRET")
            if all([tenant_id, client_id, client_secret]):
                credential = ClientSecretCredential(
                    tenant_id=tenant_id,
                    client_id=client_id,
                    client_secret=client_secret
                )
                token_provider = get_bearer_token_provider(
                    credential,
                    "https://cognitiveservices.azure.com/.default"
                )
                return token_provider
            else:
                return None
            
        except Exception as e:
            return None
        
    def openai_client(self):
        token = self.get_access_token()
        if token is not None:
            return AzureOpenAIClient(
                api_version=os.getenv("AZURE_OPENAI_API_VERSION"),
                azure_endpoint=os.getenv("AZURE_OPENAI_ENDPOINT"),
                azure_ad_token_provider=token
            )
        else:
            return None
        
    def call_open_ai(self,user_prompt: str,system_prompt: str = None):
            messages = [
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_prompt}
                ]
            client = self.openai_client()
            if not client:
                raise ValueError("OpenAI client is not initialized. Please check your configuration.")
            response = client.chat.completions.create(
                model=os.getenv("AZURE_OPENAI_MODEL_NAME"),
                messages=messages,
                temperature=0
            )
            return response.choices[0].message.content.strip()
    
    def validate_sql_statement(self, prompt: str):
        return self.call_open_ai(user_prompt=prompt, system_prompt="You are an assistant that helps validating SQL statement.Only output true or false.")
    
    def get_refinery_short_name(self, user_prompt):
        prompt_lower = user_prompt.lower()
        
        # Check for Richmond refinery identifiers
        if any(identifier in prompt_lower for identifier in ["ri", "ric", "richmond"]):
            return "RI"
        # Check for Salt Lake City refinery identifiers
        elif any(identifier in prompt_lower for identifier in ["sl", "slc", "salt lake"]):
            return "SL"
        # Check for El Segundo refinery identifiers
        elif any(identifier in prompt_lower for identifier in ["es", "el segundo"]) or "tracker" in prompt_lower:
            return "ES"
        # Check for Pascagoula refinery identifiers
        elif any(identifier in prompt_lower for identifier in ["pa", "pas", "pascagoula"]):
            return "PA"
        else:
            return "RI"
        
    def detect_sql_file(self,user_prompt):
        prompt_lower = user_prompt.lower()
        if "ost" in prompt_lower:
            return os.path.join(os.getcwd(), 'app', 'sql','overdue_ost.sql'),'Overdue OST'
        elif "cap tasks" in prompt_lower:
            return os.path.join(os.getcwd(), 'app', 'sql','overdue_cap_tasks.sql'), 'Overdue CAP Tasks'
        elif "action" in prompt_lower or "tracker" in prompt_lower:
            return os.path.join(os.getcwd(), 'app', 'sql','action_tracker.sql'), 'Action Tracker'
        else:
            return None, "No matching SQL file found"

   