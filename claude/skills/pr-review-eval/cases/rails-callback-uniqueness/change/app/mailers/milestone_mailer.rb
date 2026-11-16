class MilestoneMailer < ApplicationMailer
  def reached
    @count = params[:count]
    mail(to: params[:user].email, subject: "#{@count} appellations tasted!")
  end
end
