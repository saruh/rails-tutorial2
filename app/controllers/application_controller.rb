class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  #protect_from_forgery with: :exception
  include SessionsHelper

  protected

    # csv 出力時に BOM を付与する
    def send_data_with_bom(csv, options = {})
      bom = "   "
      bom.setbyte(0, 0xEF)
      bom.setbyte(1, 0xBB)
      bom.setbyte(2, 0xBF)
      send_data bom + csv.to_s, options
    end

    # csv 出力時に shift-jis で出力する
    def send_data_with_sjis(csv, options = {type: 'text/csv; charset=shift_jis', filename: 'data.csv'})
      send_data csv.to_s, options
    end
end
