require 'fastlane/action'
require_relative '../helper/bitbucket_cloud_helper'

module Fastlane
  module Actions
    module SharedValues
      BITBUCKET_CREATE_PULL_REQUEST_RESULT = :BITBUCKET_CREATE_PULL_REQUEST_RESULT
    end

    class BitbucketCreatePullRequestAction < Action
      def self.run(options)
        require 'excon'

        company_host_name = options[:company_host_name]
        repository_name = options[:repository_name]
        destination_branch = options[:destination_branch]
        description = options[:description]
        reviewers = options[:reviewers]

        api_token = Base64.strict_encode64("#{options[:username]}:#{options[:password]}")

        api_url = "https://api.bitbucket.org/2.0/repositories/#{company_host_name}/#{repository_name}/pullrequests"

        headers = { "Content-Type": "application/json", Authorization: "Basic #{api_token}" }

        payload = {
          title: options[:title],
          source: {
              branch: {
                  name: options[:source_branch]
              }
          }
        }

        if destination_branch.instance_of?(NilClass)
          destination_log = ""
        else
          destination_obj = {
            branch: {
                name: destination_branch
            }
          }
          payload[:destination] = destination_obj
          destination_log = " to '#{destination_branch}'"
        end

        if description.instance_of?(NilClass)
          description_log = ""
        else
          payload[:description] = description
          description_log = " and description '#{description}'"
        end

        unless reviewers.instance_of?(NilClass)
          reviewers_obj = reviewers.map do |reviewer|
            {
              username: reviewer

            }
          end
          payload[:reviewers] = reviewers_obj
        end

        payload = payload.to_json

        puts("Plugin Bitbucket will create a new pull request from '#{options[:source_branch]}'#{destination_log} with title '#{options[:title]}'#{description_log}")

        response = Excon.post(api_url, headers: headers, body: payload)

        result = self.formatted_result(response)

        UI.important("Plugin Bitbucket finished with result")
        UI.important(result.to_s)

        Actions.lane_context[SharedValues::BITBUCKET_CREATE_PULL_REQUEST_RESULT] = formatted_context_result(response)

        if result[:status] != 201
          error_message = "Plugin Bitbucket finished with error code #{result[:status]} #{result[:reason_phrase]}"
          raise StandardError, error_message
        end

        UI.success("Successfully create a new Bitbucket pull request!")
        return result
      end

      def self.formatted_result(response)
        {
          status: response[:status],
          reason_phrase: response[:reason_phrase],
          body: response.body || "",
          json: self.parse_json(response.body) || {}
        }
      end

      def self.formatted_context_result(response)
        "Status code: #{response[:status]}, reason: #{response[:reason_phrase]}"
      end

      def self.parse_json(value)
        require 'json'

        JSON.parse(value)
      rescue JSON::ParserError
        nil
      end

      def self.description
        "Create a new pull request inside your Bitbucket project"
      end

      def self.details
        "Wrapper of Bitbucket cloud rest apis in order to make easy integration of Bitbucket CI inside fastlane workflow"
      end

      def self.authors
        ["Luca Tagliabue"]
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :username,
                                       env_name: "FL_POST_BITBUCKET_PULL_REQUEST_USERNAME",
                                       description: "Bitbucket username",
                                       sensitive: true,
                                       code_gen_sensitive: true,
                                       is_string: true,
                                       default_value: ENV.fetch("BITBUCKET_USERNAME", nil),
                                       default_value_dynamic: true,
                                       optional: false),
          FastlaneCore::ConfigItem.new(key: :password,
                                       env_name: "FL_POST_BITBUCKET_PULL_REQUEST_PASSWORD",
                                       description: "Bitbucket password",
                                       sensitive: true,
                                       code_gen_sensitive: true,
                                       is_string: true,
                                       default_value: ENV.fetch("BITBUCKET_PASSWORD", nil),
                                       default_value_dynamic: true,
                                       optional: false),
          FastlaneCore::ConfigItem.new(key: :company_host_name,
                                       env_name: "FL_POST_BITBUCKET_PULL_REQUEST_COMPANY_HOST_NAME",
                                       description: "Bitbucket company host name",
                                       sensitive: true,
                                       code_gen_sensitive: true,
                                       is_string: true,
                                       default_value: ENV.fetch("BITBUCKET_COMPANY_HOST_NAME", nil),
                                       default_value_dynamic: true,
                                       optional: false),
          FastlaneCore::ConfigItem.new(key: :repository_name,
                                       env_name: "FL_POST_BITBUCKET_PULL_REQUEST_REPOSITORY_NAME",
                                       description: "Bitbucket repository name",
                                       sensitive: true,
                                       code_gen_sensitive: true,
                                       is_string: true,
                                       default_value: ENV.fetch("BITBUCKET_REPOSITORY_NAME", nil),
                                       default_value_dynamic: true,
                                       optional: false),
          FastlaneCore::ConfigItem.new(key: :title,
                                       env_name: "FL_POST_BITBUCKET_PULL_REQUEST_TITLE",
                                       description: "Title of the pull request",
                                       is_string: true,
                                       optional: false),
          FastlaneCore::ConfigItem.new(key: :description,
                                       env_name: "FL_POST_BITBUCKET_PULL_REQUEST_DESCRIPTION",
                                       description: "Description of the pull request",
                                       is_string: true,
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :reviewers,
                                       env_name: "FL_POST_BITBUCKET_PULL_REQUEST_REVIEWERS",
                                       description: "List of reviewer's usernames for the pull request. If no reviewers are passed, fails back to default ones",
                                       type: Array,
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :source_branch,
                                       env_name: "FL_POST_BITBUCKET_PULL_REQUEST_SOURCE_BRANCH",
                                       description: "Name of the source branch",
                                       is_string: true,
                                       optional: false),
          FastlaneCore::ConfigItem.new(key: :destination_branch,
                                       env_name: "FL_POST_BITBUCKET_PULL_REQUEST_DESTINATION_BRANCH",
                                       description: "Name of the destination branch",
                                       is_string: true,
                                       optional: true)
        ]
      end

      def self.output
        [
          ['BITBUCKET_CREATE_PULL_REQUEST_RESULT', 'The result of the bitbucket rest cloud api']
        ]
      end

      def self.return_value
        'The result of the bitbucket rest cloud api'
      end

      def self.example_code
        [
          'bitbucket_create_pull_request(
              username: "YOUR_USERNAME_HERE",
              password: "YOUR_PASSWORD_HERE",
              company_host_name: "YOUR_COMPANY_HOST_HERE",
              repository_name: "YOUR_REPOSITORY_NAME_HERE",
              title: "PULL_REQUEST_TITLE_HERE",
              description: "PULL_REQUEST_DESCRIPTION_HERE",
              reviewers: ["FIRST_REVIEWER", "SECOND_REVIEWER"],
              source_branch: "YOUR_SOURCE_BRANCH_HERE",
              destination_branch: "YOUR_DESTINATION_BRANCH_HERE"
          )'
        ]
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end