module Lipsiadmin
  module Mailer
    # This module convert a string/controller to a pdf through Pd4ml java library (included in this plugin)
    # 
    # PD4ML is a powerful PDF generating tool that uses HTML and CSS (Cascading Style Sheets) as page layout 
    # and content definition format. Written in 100% pure Java, it allows users to easily add PDF generation 
    # functionality to end products.
    # 
    # For generate a pdf you can simply do
    #   
    #     script/generate pdf invoice
    # 
    # then edit your template /app/views/pdf/invoice.html.haml
    # 
    # Then in any of your mailers add some like this:
    # 
    #   def order_invoiced(order)
    #     recipients my@mail.com
    #     from       my@server.com
    #     subject    Your Invoice
    #
    #     attachment "application/pdf" do |a|
    #       a.body = render_pdf(:invoice, :invoice => order.invoice, :other => order.invoice.other)
    #     end
    #
    #     part "text/plain" do |a|
    #       a.body = render_message("order_invoiced", :order => order, :body_template => @body_template)
    #     end       
    #   end
    #
    # Lipsiadmin include a trial fully functional evaluation version, but if you want buy it, 
    # go here: http://pd4ml.com/buy.htm and then put your licensed jar in a directory in your
    # project then simply calling this:
    # 
    #   Lipsiadmin::Utils::PdfBuilder::JARS_PATH = "here/is/my/licensed/pd4ml"
    # 
    # you can use your version without any problem.
    #
    # By default Lipsiadmin will look into your "vendor/pd4ml" and if:
    # 
    # * pd4ml.jar
    # * ss_css2.jar
    # 
    # are present will use it
    #
    module PdfBuilder
      include Lipsiadmin::Utils::HtmlEntities
      
      # Convert a stream to pdf, the template must be located in app/view/pdf/yourtemplate.pdf.erb
      def render_pdf(template, body)
        
        # path to the pd4ml jarfile
        jars_path = Lipsiadmin::Utils::PdfBuilder::JARS_PATH

        # set the landescape
        landescape = (body[:landescape].delete || false)
        
        # encode the template
        input = encode_entities(render_message("/pdf/#{template}.html.haml", body))

        # search for stylesheet links and make their paths absolute.
        input.gsub!('<link href="/javascripts', '<link href="' + RAILS_ROOT + '/public/javascripts')
        input.gsub!('<link href="/stylesheets', '<link href="' + RAILS_ROOT + '/public/stylesheets')   

        # search for images src, append full-path.
        input.gsub!('src="/', 'src="' + RAILS_ROOT + '/public/')
        input.gsub!('url(','url('+RAILS_ROOT+'/public')

        cmd = "java -Xmx512m -Djava.awt.headless=true -cp #{jars_path}/pd4ml.jar:.:#{jars_path} Pd4Ruby '#{input}' 950 A4 #{landescape}"

        output = %x[cd #{Lipsiadmin::Utils::PdfBuilder::PD4RUBY_PATH} \n #{cmd}]

        # raise error if process returned false (ie: a java error)
        raise PdfError, "An unknonwn error occurred while generating pdf: cd #{Lipsiadmin::Utils::PdfBuilder::PD4RUBY_PATH} && #{cmd}" if $?.success? === false

        #return raw pdf binary-stream
        output                
      end
    end

    # Errors For PDF
    class PdfError < StandardError#:nodoc:
    end
  end
end