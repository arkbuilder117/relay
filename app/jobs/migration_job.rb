class MigrationJob < ApplicationJob
  queue_as :default

  def perform(migration_id)
    migration = Migration.find(migration_id)
    return if migration.status == "completed"

    user         = User.find(migration.user_id)
    orchestrator = Migrations::Services::MigrationOrchestrator.new(migration, user)

    orchestrator.on(:playlist_completed) do |result|
      Turbo::StreamsChannel.broadcast_replace_to(
        "migration_#{migration.id}",
        target:  "playlist_result_#{result.id}",
        partial: "migrations/playlist_result",
        locals:  { result: result }
      )
      migration.reload
      Turbo::StreamsChannel.broadcast_replace_to(
        "migration_#{migration.id}",
        target:  "migration-summary",
        partial: "migrations/summary",
        locals:  { migration: migration }
      )
    end

    orchestrator.run

    migration.reload
    Turbo::StreamsChannel.broadcast_replace_to(
      "migration_#{migration.id}",
      target:  "migration-status",
      partial: "migrations/status_badge",
      locals:  { migration: migration }
    )
    Turbo::StreamsChannel.broadcast_replace_to(
      "migration_#{migration.id}",
      target:  "migration-actions",
      partial: "migrations/actions",
      locals:  { migration: migration }
    )

    if migration.status == "completed" && migration.playlist_results.none? { |r| r.status == "failed" }
      SpotifyAccount.where(user_id: migration.user_id).destroy_all
      AppleMusicAccount.where(user_id: migration.user_id).destroy_all
    end
  end
end
