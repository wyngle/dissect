module Dissect 
  module Helpers

    # Helpers for rendering stuff
    #
    module RenderHelpers

      # Used by #http_error
      #
      HTTP_CODES = {
        400 => 'bad request',
        404 => 'resource not found',
        412 => 'precondition failed'
      }

      # HTTP errors
      #
      def http_error(code, cause=nil)

        @code = code
        @message = HTTP_CODES[code]
        @cause = cause

        @trace = if cause
          [ cause.message ] + cause.backtrace
        else
          nil
        end

        @format = if m = @format.to_s.match(/^[^\/]+\/([^;]+)/)
          m[1].to_sym
        else
          @format
        end

        status(@code)

        respond_to do |format|
          format.html { erb :http_error }
          format.json { json(:http_error, [ @code, @message, @cause ]) }
        end
      end

    end
  end
end

