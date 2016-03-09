require 'sinatra'
require 'sinatra/cookies'
require 'tilt/erb'
require 'turbolinks/source'

module TurbolinksDemo
  class App < Sinatra::Base
    helpers Sinatra::Cookies

    get '/' do
      @title = 'Demo'
      erb :index, layout: :layout
    end

    get '/one' do
      @title = 'Page One'
      erb :one, layout: :layout
    end

    get '/two' do
      @title = 'Page Two'
      erb :two, layout: :layout
    end

    get '/slow' do
      sleep 2
      @title = 'Slow Page'
      erb :slow, layout: :layout
    end

    get '/protected' do
      if cookies[:signed_in]
        @title = 'Protected'
        erb :protected, layout: :layout
      else
        throw :halt, [ 401, 'Unauthorized' ]
      end
    end

    get '/sign-in' do
      @title = 'Sign In'
      erb :sign_in, layout: :layout
    end

    post '/sign-in' do
      cookies[:signed_in] = true
      redirect to('/')
    end

    get '/turbolinks.js' do
      send_file(Turbolinks::Source.asset_path + '/turbolinks.js')
    end
  end
end
