require 'coderay'

module DeploysHelper
  def deploy_active?
    @deploy.active? && (JobExecution.find_by_id(@deploy.job_id) || JobExecution.enabled)
  end

  def deploy_page_title
    "#{@deploy.stage.name} deploy (#{@deploy.status}) - #{@project.name}"
  end

  def file_status_label(status)
    mapping = {
      "added"    => "success",
      "modified" => "info",
      "removed"  => "danger"
    }

    type = mapping[status]

    content_tag :span, status[0].upcase, class: "label label-#{type}"
  end

  def file_changes_label(count, type)
    content_tag :span, count.to_s, class: "label label-#{type}" unless count.zero?
  end

  def github_users(users)
    users.map {|user| github_user_avatar(user) }.join(" ").html_safe
  end

  def github_user_avatar(user)
    return if user.nil?

    link_to user.url, title: user.login do
      image_tag user.avatar_url, width: 20, height: 20
    end
  end

  def deploy_status_panel(deploy)
    deploy_status_panel_common(deploy, BuddyCheck.enabled?)
  end

  def buddy_check_button(project, deploy)
    return nil unless deploy.waiting_for_buddy?

    button_class = ['btn']

    if @deploy.started_by?(current_user)
      button_text = 'Bypass'
      button_class << 'btn-danger'
    else
      button_text = 'Approve'
      button_class << 'btn-primary'
    end

    link_to button_text, buddy_check_project_deploy_path(@project, @deploy), method: :post, class: button_class.join(' ')
  end

  def duration_text(deploy)
    dt_start = BuddyCheck.enabled? ? deploy.started_at || deploy.updated_at : deploy.created_at
    seconds  = (deploy.updated_at - dt_start).to_i

    duration = ""

    if seconds > 60
      minutes = seconds / 60
      seconds = seconds - minutes * 60

      duration += "#{minutes} minute".pluralize(minutes)
    end

    duration += (seconds > 0 || duration.size == 0 ? " #{seconds} second".pluralize(seconds) : "")
  end

  def syntax_highlight(code, language = :ruby)
    CodeRay.scan(code, language).html.html_safe
  end

  def stages_select_options
    @project.stages.unlocked.map do |stage|
      [stage.name, stage.id, 'data-confirmation' => stage.confirm?]
    end
  end

  private

    def deploy_status_panel_common(deploy, enabled, hash = { "cancelled" => "danger" } )
      mapping = {
        "succeeded" => "success",
        "failed"    => "danger",
        "errored"   => "warning",
      }

      mapping = mapping.merge(hash) if enabled

      content, status = content_no_buddy_check(deploy)

      content ||= h deploy.summary
      status ||= mapping.fetch(deploy.status, "info")

      content_tag :div, content.html_safe, class: "alert alert-#{status}"
    end

    def content_no_buddy_check(deploy)
      if deploy.finished?
        content = h "#{deploy.summary} "
        content << content_tag(:span, deploy.created_at.rfc822, data: { time: datetime_to_js_ms(deploy.created_at) })
        content << ", it took #{duration_text(deploy)}."
      end
    end

end
