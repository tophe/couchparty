require 'digest'

module CouchParty


  class Attachment

    attr_reader :attachment, :content, :doc

    # doc, change ruby symbol to string
    def initialize(attachment, content, doc = nil)
      @attachment = attachment
      @content = content
      @doc = doc

      check_md5! if @doc
    end

    def loaded?
      true unless @content.nil?
    end

    # raise error on invalid md5
    def check_md5!
      return unless loaded?
      digest = 'md5-' + Digest::MD5.base64digest(@content)
      raise 'content md5 invalid ' if digest != @attachment['digest']
    end

    # save attachment to file
    def save(path)
      raise "no content loaded" unless loaded?
      File.open(path, 'w') {|io| io.write(content)}

    end
  end
end
