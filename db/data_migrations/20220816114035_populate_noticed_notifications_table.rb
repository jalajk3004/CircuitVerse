class PopulateNoticedNotificationsTable < ActiveRecord::DataMigration
  class Notification < ActiveRecord::Base
    belongs_to :notifiable, polymorphic: true
  end

  def up
    Notification.where(migrated: false).find_each do |notification|
      NoticedNotification.transaction do
        new_notification = NoticedNotification.create!(
          :recipient_type => notification.target_type,
          :recipient_id => notification.target_id,
          :type => (notification.notifiable_type == "Star" ? "StarNotification" : "ForkNotification"),
          :params => {
            user: User.find(notification.notifier_id),
            project: (notification.notifiable_type == "Star" ? Project.find(notification.notifiable.project_id) : Project.find(notification.notifiable.forked_project_id))
          },
          :read_at => notification.opened_at
        )
        notification.update(migrated: true)
      end
      rescue StandardError => e
        Rails.logger.info e.message
    end
  end
end