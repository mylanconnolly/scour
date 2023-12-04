require 'test_helper'

module Scour
  class ScourTest < ActiveSupport::TestCase
    # Test sorting functionality in the model itself
    [
      ['username', '"users"."username" ASC'],
      ['-username', '"users"."username" DESC'],
      [%w[username email], '"users"."username" ASC, "users"."email" ASC'],
      [%w[username -email], '"users"."username" ASC, "users"."email" DESC']
    ].each do |sort, expected|
      test "when given #{sort.inspect}, it sorts by #{expected.inspect}" do
        sql = User.scour(_sort: sort).to_sql

        want = <<~SQL.squish
          SELECT
            "users".*
          FROM
            "users"
          ORDER BY
            #{expected}
        SQL

        assert_equal want, sql
      end
    end

    # Test sorting by associated columns
    [
      ['comments.created_at', '"comments"."created_at" ASC'],
      [%w[comments.created_at -comments.updated_at], '"comments"."created_at" ASC, "comments"."updated_at" DESC']
    ].each do |sort, expected|
      test "when given #{sort.inspect}, it sorts by #{expected.inspect}" do
        sql = User.scour(_sort: sort).to_sql

        want = <<~SQL.squish
          SELECT
            "users".*
          FROM
            "users"
            LEFT OUTER JOIN "comments" ON "comments"."user_id" = "users"."id"
          ORDER BY
            #{expected}
        SQL

        assert_equal want, sql
      end
    end

    # Test query criteria in the model itself
    [
      [{ username: { eq: 'foo' } }, '("users"."username" = \'foo\')'],
      [{ username: { not_eq: 'foo' } }, '("users"."username" != \'foo\')'],
      [{ created_at: { gt: '2019-01-01' } }, '("users"."created_at" > \'2019-01-01 00:00:00\')'],
      [{ created_at: { gteq: '2019-01-01' } }, '("users"."created_at" >= \'2019-01-01 00:00:00\')'],
      [{ created_at: { lt: '2019-01-01' } }, '("users"."created_at" < \'2019-01-01 00:00:00\')'],
      [{ created_at: { lteq: '2019-01-01' } }, '("users"."created_at" <= \'2019-01-01 00:00:00\')'],
      [
        { or: { created_at: { lteq: '2019-01-01' }, updated_at: { lteq: '2019-01-01' } } },
        '(("users"."created_at" <= \'2019-01-01 00:00:00\') OR ("users"."updated_at" <= \'2019-01-01 00:00:00\'))'
      ],
      [
        { and: { created_at: { lteq: '2019-01-01' }, updated_at: { lteq: '2019-01-01' } } },
        '("users"."created_at" <= \'2019-01-01 00:00:00\') AND ("users"."updated_at" <= \'2019-01-01 00:00:00\')'
      ]
    ].each do |query, expected|
      test "when given #{query.inspect}, it filters by #{expected.inspect}" do
        sql = User.scour(query).to_sql

        want = <<~SQL.squish
          SELECT
            "users".*
          FROM
            "users"
          WHERE
            #{expected}
        SQL

        assert_equal want, sql
      end
    end

    # Test query criteria in associated columns
    [
      [{ comments: { created_at: { gt: '2019-01-01' } } }, '("comments"."created_at" > \'2019-01-01 00:00:00\')']
    ].each do |query, expected|
      test "when given #{query.inspect}, it filters by #{expected.inspect}" do
        sql = User.scour(query).to_sql

        want = <<~SQL.squish
          SELECT
            "users".*
          FROM
            "users"
            LEFT OUTER JOIN "comments" ON "comments"."user_id" = "users"."id"
          WHERE
            #{expected}
        SQL

        assert_equal want, sql
      end
    end
  end
end
