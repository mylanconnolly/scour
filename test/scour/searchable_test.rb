require 'test_helper'

module Scour
  class ScourTest < ActiveSupport::TestCase
    DUMMY_CRITERIA = {
      and: {
        last_name: {
          eq: 'Doe'
        },
        first_name: {
          eq: 'John'
        }
      },
      or: {
        username: {
          eq: 'foo'
        },
        email: {
          eq: 'foo'
        }
      },
      created_at: {
        gteq: '2023-08-02 20:17:22.521227',
        lteq: '2023-08-03 20:17:22.521410'
      },
      comments: {
        subject: {
          eq: 'Hello'
        },
        created_at: {
          eq_month: '2023-08-02'
        },
        'data.meta.tag': {
          eq: 'foo'
        }
      }
    }.freeze

    DUMMY_SQL = <<~SQL.squish
      SELECT
        "users".*
      FROM
        "users"
        INNER JOIN "comments" ON "comments"."user_id" = "users"."id"
      WHERE
        ("users"."last_name" = 'Doe')
        AND ("users"."first_name" = 'John')
        AND (("users"."username" = 'foo') OR ("users"."email" = 'foo'))
        AND ("users"."created_at" >= '2023-08-02 20:17:22.521227'
          AND "users"."created_at" <= '2023-08-03 20:17:22.521410')
        AND (("comments"."subject" = 'Hello')
          AND (DATE_TRUNC('month', "comments"."created_at") = DATE_TRUNC('month', '2023-08-02'))
          AND "comments"."data" -> 'meta' ->> 'tag')
    SQL

    test 'it defines the scour method' do
      assert_nothing_raised { User.scour }
      assert_nothing_raised { User.scour(DUMMY_CRITERIA) }
    end

    test 'it writes the SQL as expected' do
      assert_equal DUMMY_SQL, User.scour(DUMMY_CRITERIA).to_sql
    end
  end
end
