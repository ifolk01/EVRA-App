#
//  ranking_push.py
//  Velos
//
//  Created by Filipe Pinto Cunha on 24/08/26.
//

import os
import datetime
import requests
import hashlib
import ecdsa
import base64

# Configurações do seu CloudKit
CONTAINER = "iCloud.filipecunha.dev.EVRA" # Confirme se é este o nome exato do seu container
ENVIRONMENT = "development" # Mude para "production" quando lançar na App Store
KEY_ID = os.environ.get("CLOUDKIT_KEY_ID")
PRIVATE_KEY_STR = os.environ.get("CLOUDKIT_PRIVATE_KEY")

def generate_signature(date_str, payload_str, path):
    """Gera a assinatura criptográfica exigida pela Apple (ECDSA)"""
    private_key = ecdsa.SigningKey.from_pem(PRIVATE_KEY_STR)
    
    # Faz o hash do body da requisição
    body_hash = hashlib.sha256(payload_str.encode('utf-8')).digest()
    body_base64 = base64.b64encode(body_hash).decode('utf-8')
    
    # Monta a string que será assinada
    msg_to_sign = f"{date_str}:{body_base64}:{path}"
    
    # Assina e converte para base64
    signature = private_key.sign(msg_to_sign.encode('utf-8'), hashfunc=hashlib.sha256, sigencode=ecdsa.util.sigencode_der)
    return base64.b64encode(signature).decode('utf-8')

def send_ranking_push():
    # 1. Monta o texto dinâmico (Aqui você pode fazer uma query antes para pegar os nomes reais)
    # Exemplo estático para testarmos a infraestrutura:
    message_text = "🏆 Fim do mês a chegar! Verifica o Top 3 do Ranking Global e garante os teus pontos!"
    
    # 2. O Payload (Corpo da requisição para criar o RankingAnnouncement)
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
    import json
    payload_str = json.dumps(payload)
    
    # 3. Preparar a chamada para a Apple
    path = f"/database/1/{CONTAINER}/{ENVIRONMENT}/public/records/modify"
    url = f"https://api.apple-cloudkit.com{path}"
    date_str = datetime.datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ')
    
    signature = generate_signature(date_str, payload_str, path)
    
    headers = {
        "X-Apple-CloudKit-Request-KeyID": KEY_ID,
        "X-Apple-CloudKit-Request-ISO8601Date": date_str,
        "X-Apple-CloudKit-Request-SignatureV1": signature,
        "Content-Type": "application/json"
    }
    
    # 4. Disparar!
    print("A enviar notificação para o CloudKit...")
    response = requests.post(url, headers=headers, data=payload_str)
    
    if response.status_code == 200:
        print("✅ Sucesso! O CloudKit recebeu o registo e vai disparar as Push Notifications!")
    else:
        print(f"❌ Erro {response.status_code}: {response.text}")

if __name__ == "__main__":
    if not KEY_ID or not PRIVATE_KEY_STR:
        print("Erro: Chaves de autenticação não encontradas nas variáveis de ambiente.")
    else:
        send_ranking_push()
