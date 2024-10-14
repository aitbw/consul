class Admin::Poll::Shifts::FormComponent < ApplicationComponent
  attr_reader :shift, :booth, :officer

  def initialize(shift, booth:, officer:)
    @shift = shift
    @booth = booth
    @officer = officer
  end

  private

    def voting_polls
      booth.polls.current
    end

    def recount_polls
      booth.polls.current_or_recounting
    end

    def shift_vote_collection_dates(polls)
      return [] if polls.blank?

      date_options((start_date(polls)..end_date(polls)), Poll::Shift.tasks[:vote_collection])
    end

    def shift_recount_scrutiny_dates(polls)
      return [] if polls.blank?

      dates = polls.map(&:ends_at).map(&:to_date).sort.reduce([]) do |total, date|
        initial_date = [date, Date.current].max
        total << (initial_date..date + Poll::RECOUNT_DURATION).to_a
      end
      date_options(dates.flatten.uniq, Poll::Shift.tasks[:recount_scrutiny])
    end

    def date_options(dates, task_id)
      valid_dates(dates, task_id).map { |date| [l(date, format: :long), l(date)] }
    end

    def valid_dates(dates, task_id)
      dates.reject { |date| officer_shifts(task_id).include?(date) }
    end

    def start_date(polls)
      start_date = polls.minimum(:starts_at).to_date
      [start_date, Date.current].max
    end

    def end_date(polls)
      polls.maximum(:ends_at).to_date
    end

    def officer_shifts(task_id)
      officer.shifts.where(task: task_id, booth: booth).map(&:date)
    end
end
