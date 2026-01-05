json.(webhook, :id, :name, :url, :active, :signing_secret, :subscribed_actions)
json.board_id webhook.board_id
json.created_at webhook.created_at.utc
json.updated_at webhook.updated_at.utc
