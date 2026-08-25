# ranking_push.py
# Velos
# Created by Filipe Pinto Cunha on 24/08/26.

import os
import datetime
import requests
import hashlib
import ecdsa
import base64
import json
import math

# Configurações do seu CloudKit
CONTAINER = "iCloud.filipecunha.dev.EVRA"
ENVIRONMENT = "development"
KEY_ID = os.environ.get("CLOUDKIT_KEY_ID")
PRIVATE_KEY_STR = os.environ.get("CLOUDKIT_PRIVATE_KEY")

def generate_signature(date_str, payload_str, path):
    """Gera a assinatura criptográfica exigida pela Apple (ECDSA)"""
    normalized_key = PRIVATE_KEY_STR.replace("BEGIN EC PRIVATE KEY", "BEGIN PRIVATE KEY")
    normalized_key = normalized_key.replace("END EC PRIVATE KEY", "END PRIVATE KEY")
    private_key = ecdsa.SigningKey.from_pem(normalized_key)
    
    body_hash = hashlib.sha256(payload_str.encode('utf-8')).digest()
    body_base64 = base64.b64encode(body_hash).decode('utf-8')
    
    msg_to_sign = f"{date_str}:{body_base64}:{path}"
    
    signature = private_key.sign(msg_to_sign.encode('utf-8'), hashfunc=hashlib.sha256, sigencode=ecdsa.util.sigencode_der)
    return base64.b64encode(signature).decode('utf-8')

def make_cloudkit_request(path, payload):
    """Função auxiliar para fazer os pedidos à Apple de forma limpa"""
    url = f"https://api.apple-cloudkit.com{path}"
    payload_str = json.dumps(payload)
    date_str = datetime.datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ')
    signature = generate_signature(date_str, payload_str, path)
    
    headers = {
        "X-Apple-CloudKit-Request-KeyID": KEY_ID,
        "X-Apple-CloudKit-Request-ISO8601Date": date_str,
        "X-Apple-CloudKit-Request-SignatureV1": signature,
        "Content-Type": "application/json"
    }
    return requests.post(url, headers=headers, data=payload_str)

def get_top_3_users():
    """Busca os 3 utilizadores com mais pontos no Banco de Dados Público"""
    path = f"/database/1/{CONTAINER}/{ENVIRONMENT}/public/records/query"
    
    # Query procurando a tabela LevUser e ordenando do maior para o menor
    payload = {
        "query": {
            "recordType": "LevUser",
            "sortBy": [{"fieldName": "totalCarbonPoints", "order": "descending"}]
        },
        "resultsLimit": 3
    }
    
    response = make_cloudkit_request(path, payload)
    
    if response.status_code == 200:
        records = response.json().get("records", [])
        top_users = []
        for r in records:
            name = r.get("fields", {}).get("name", {}).get("value", "Ciclista")
            points = r.get("fields", {}).get("totalCarbonPoints", {}).get("value", 0)
            top_users.append((name, points))
        return top_users
    else:
        print(f"Erro ao buscar ranking: {response.text}")
        return []

def send_ranking_push():
    # 1. Determina a semana do mês atual (1 a 5)
    day_of_month = datetime.datetime.utcnow().day
    week_number = math.ceil(day_of_month / 7.0)
    
    # 2. Vai à nuvem buscar quem está a ganhar
    top_users = get_top_3_users()
    
    # 3. Máquina de Estados da Mensagem
    if week_number == 1:
        # Primeira semana: Foco na motivação de arranque
        message_text = "🏁 Novo mês, novo ranking no Velos! As pontuações estão a zeros. Quem vai dominar as ruas de bicicleta esta semana?"
        
    else:
        # Monta a string de quem está a ganhar
        if len(top_users) >= 3:
            ranking_str = f"1º {top_users[0][0]} ({top_users[0][1]}pts), 2º {top_users[1][0]}, 3º {top_users[2][0]}"
        elif len(top_users) > 0:
            ranking_str = f"1º {top_users[0][0]} ({top_users[0][1]}pts)"
        else:
            ranking_str = "Ainda não há pontuações. Seja o primeiro a pedalar"

        if week_number >= 4:
            # Últimas semanas do mês: Foco na urgência
            message_text = f"🏆 Reta final do mês! {ranking_str}. Vai ficar para trás? Pega na bicicleta!"
        else:
            # Meio do mês: Foco na competição
            message_text = f"🔥 O ranking está a aquecer! {ranking_str}. Consegues apanhá-los?"
            
    print(f"Mensagem gerada: {message_text}")
    
    # 4. Inserir o registo para despoletar a notificação no iPhone
    path = f"/database/1/{CONTAINER}/{ENVIRONMENT}/public/records/modify"
    payload = {
        "operations": [{
            "operationType": "create",
            "record": {
                "recordType": "RankingAnnouncement",
                "fields": {
                    "messageText": {"value": message_text}
                }
            }
        }]
    }
    
    response = make_cloudkit_request(path, payload)
    
    if response.status_code == 200:
        print("✅ Sucesso! Mensagem dinâmica inserida no CloudKit.")
    else:
        print(f"❌ Erro ao enviar push: {response.text}")

if __name__ == "__main__":
    if not KEY_ID or not PRIVATE_KEY_STR:
        print("Erro: Chaves de autenticação em falta.")
    else:
        send_ranking_push()
