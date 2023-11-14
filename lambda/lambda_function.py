import requests
import json


def lambda_handler(event, context):
    
    # HTTP method and URL
    method = event['httpMethod']
    url = event['url']
    
    # Check if the URL starts with 'https://'
    if not url.startswith('https://'):
        return {
            'statusCode': 400,
            'body': 'Only HTTPS calls are allowed'
        }
        
    response = None
    auth = None
    
    # custom headers
    headers = event.get('headers', {})
    # connection close header
    #headers['Connection'] = 'close'  
    
    # authentication credentials
    if 'auth' in event:
        auth = event.get('auth', None)
        auth = requests.auth.HTTPBasicAuth(event['auth']['username'], event['auth']['password'])
        
    # timeout
    timeout = event.get('timeout', None)
    
    try:
        if method == 'GET':
            response = requests.get(url, headers=headers, auth=auth, params=event.get('params', {}), timeout=timeout)
            
        elif method == 'PUT':
            content_type = headers.get('Content-Type', '')
            if 'application/json' in content_type:
                data = json.dumps(event.get('body', {}))
            elif 'application/x-www-form-urlencoded' in content_type:
                data = event.get('body', {})
            elif 'text/xml' in content_type:
                data = event.get('body', {})
            else:
                data = event.get('body', {})
            
            response = requests.put(url, data=data, headers=headers, auth=auth, params=event.get('params', {}), timeout=timeout)
            
        elif method == 'POST':
            content_type = headers.get('Content-Type', '')
            if 'application/json' in content_type:
                data = json.dumps(event.get('body', {}))
            elif 'application/x-www-form-urlencoded' in content_type:
                data = event.get('body', {})
            elif 'text/xml' in content_type:
                data = event.get('body', {})
            else:
                data = event.get('body', {})
            
            response = requests.post(url, data=data, headers=headers, auth=auth, params=event.get('params', {}), timeout=timeout)
            
        elif method == 'DELETE':
            response = requests.delete(url, headers=headers, auth=auth, params=event.get('params', {}), timeout=timeout)
                
        elif method == 'PATCH':
            content_type = headers.get('Content-Type', '')
            if 'application/json' in content_type:
                data = json.dumps(event.get('body', {}))
            elif 'application/x-www-form-urlencoded' in content_type:
                data = event.get('body', {})
            elif 'text/xml' in content_type:
                data = event.get('body', {})
            else:
                data = event.get('body', {})
            
            response = requests.patch(url, data=data, headers=headers, auth=auth, params=event.get('params', {}), timeout=timeout)
            
        elif method == 'HEAD':
            response = requests.head(url, headers=headers, auth=auth, params=event.get('params', {}), timeout=timeout)
            
        elif method == 'OPTIONS':
            response = requests.options(url, headers=headers, auth=auth, params=event.get('params', {}), timeout=timeout)
        
        else:
            # Unsupported HTTP method
            return {
                'statusCode': 405,
                'body': 'Unsupported HTTP method'
            }
        
        # Response from the HTTP request
        content_type = response.headers.get('content-type')
        
        if 'application/json' in content_type:
            response_data = response.json()
        
        elif 'text' in content_type:
            response_data = response.text
        
        else:
            response_data = None
        
        # Return the response from the HTTP request
        return {
            'statusCode': response.status_code,
            'headers': dict(response.headers),
            'body': response_data
        }
        
    except requests.exceptions.RequestException as e:
        # Exceptions thrown by the Requests library
        return {
            'statusCode': 500,
            'body': str(e)
        }
    
    except Exception as e:
        # Other exceptions
        return {
            'statusCode': 500,
            'body': str(e)
        }
    
    finally:
        # Close the persistent connection
        if response and response.raw:
            response.raw.close()