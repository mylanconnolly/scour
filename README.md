# Scour

This is an alternative search library, similar to Ransack.

To use, add the following to your models (or your `ApplicationRecord` class):

```ruby
include Scour::Searchable
```

Once added, you can use it like so:

```ruby
# To serach for a last name of Doe
User.scour(last_name: { eq: 'Doe' })

# To search for records created within a time range
User.scour(created_at: {
  gteq: '2023-08-02 20:17:22.521227',
  lteq: '2023-08-03 20:17:22.521410'
})
```

Note that the query syntax allows for fairly complex criteria to be expressed.
For example, given the following:

```ruby
User.scour(comments: {
  subject: {
    eq: 'Hello'
  },
  created_at: {
    eq_month: '2023-08-02'
  },
  'data.meta.tag': {
    eq: 'foo'
  }
})
```

The user would be searched for having a matching comment that:

- Has a subject equal to "Hello"
- Is created on the same month of "2023-08-02"
- Has a JSONB document in the data column that matches the PostgreSQL JSONB
  pattern `data->'meta'->>'tag' = 'foo'`

Note that you do not have to join `comments` explicitly because Scour will keep
track of that for you.

Regardless of the criteria you use, an `ActiveRecord::Relation` is returned so
you can chain ActiveRecord methods just as you'd expect.
