class SerchDataController < ApplicationController

    before_action :current_user

    def serch_config
        @serch_all = SearchDatum.where(user_id: session[:user_id])
        @serch_data = SearchDatum.new()
        puts Time.zone.name
    end
    
    def create
        @serch_all = SearchDatum.where(user_id: session[:user_id])
        @serch_data = SearchDatum.new(user_id: session[:user_id], 
                                 keyword: params[:keyword])
        @serch_data.save
        if @serch_data.save == true
            flash[:notice] = "新規に設定しました"
            redirect_to("/#{@serch_data.user_id}/serch_config")
        else 
            @error_messages = @serch_data.errors.full_messages
            render("serch_data/serch_config")
        end
    end

    def destroy
        @serch_data = SearchDatum.find_by(id: params[:id])
        if @serch_data.user_id == session[:user_id]
            #ユーザーID1はテストユーザーのため削除不可にする
            if @serch_data.user_id == 1
                flash[:notice]="テストユーザーのため削除できません"
                redirect_to("/#{@serch_data.user_id}/serch_config")
            else
                @serch_data.destroy
                flash[:notice]="削除しました。"
                redirect_to("/#{@serch_data.user_id}/serch_config")
            end
        else
            flash[:notice]="不正な操作です。"
            redirect_to("/#{@serch_data.user_id}/serch_config")
        end
    end
end
