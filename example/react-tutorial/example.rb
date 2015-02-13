require 'opal'
require 'opal-jquery'
require "json"
require 'react'

class Comment
  include React::Component
  def render
    React.create_element('div') do
      [React.create_element('h2') { params[:author] },
      React.create_element('span') { params[:text] }]
    end
  end
end 

class CommentList
  include React::Component

  def render
    React.create_element('div') do
      params[:data].each_with_index.map do |comment, idx|
        React.create_element(Comment, author: comment["author"], text:  comment["text"], key: idx) 
      end
    end
  end
end

class CommentBox
  include React::Component
  after_mount :load_comments_from_server
  define_state(:data) { [] }

  def load_comments_from_server
    HTTP.get(params[:url]) do |response|
      if response.ok?
        self.data = JSON.parse(response.body)
      else
        puts "failed :("
      end
    end
  end
  
  def handle_comment_submit(comment)
    comments = self.data
    comments.push(comment)
    self.data = comments
  end

  def render
    React.create_element('div') do
      [React.create_element('h1') { "Comments" },
       React.create_element(CommentList, data: self.data),
       React.create_element(CommentForm).on(:comment_submit) {|c| handle_comment_submit(c) }]
    end
  end
end


class CommentForm
  include React::Component

  def render
    a = React.create_element('form') do
      [
        React.create_element('input', type: "text", placeholder: "Your name", ref: "author"),
        React.create_element('input', type: "text", placeholder: "Say something...", ref: "text"),
        React.create_element('input', type: "submit", value: "Post")
      ]
    end.on(:submit) do |event|
      event.prevent_default
      author = self.refs.author.getDOMNode().value.strip
      text = self.refs.text.getDOMNode().value.strip
      return if !text || !author
      self.emit(:comment_submit, {author: author, text: text})
      self.refs.author.getDOMNode().value = ""
      self.refs.text.getDOMNode().value = ""
    end
  end
end

Document.ready? do 
  React.render React.create_element(CommentBox, url: "comments.json"), `document.getElementById('content')`
end