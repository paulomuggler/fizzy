class AddMetadataToCardsAndBoards < ActiveRecord::Migration[8.0]
  def change
    # Board metadata: project-level defaults (repo_url, base_branch, etc.)
    add_column :boards, :metadata, :json, default: {}

    # Card metadata: task-specific overrides (branch, prompt, etc.)
    add_column :cards, :metadata, :json, default: {}
  end
end
