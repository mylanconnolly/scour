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

Another example would be:

```ruby
User.scour(or: {
  username: {
    eq: 'foo'
  },
  email: {
    eq: 'foo'
  }
})
```

This would check for users who either have a username equal to 'foo' or an email
equal to 'foo'. Note that you can also use "and", if you want. The "and" and
"or" blocks can be nested as deeply as you'd like, which allows for very complex
criteria to be specified, particularly when combined with relationships.

Furthermore, you can compare columns in Scour. In the following example, we are
checking for users who have the same value as a username and email address:

```ruby
User.scour(username: { eq: { column: 'email' } })
```

These columns can exist on relations, as well. For example:

```ruby
User.scour(updated_at: { gteq: { column: 'comments.created_at' } })
```

Note that for now, you can only go one level deep. If you need to join on other
associations, you can add `has_many ... :through` associations to your model.

If you'd like to sort the result, you can use regular ActiveRecord query methods
or use the scour syntax, as shown below:

```ruby
# Sort by one attribute:
User.scour(_sort: 'username')

# Sort by multiple attributes in order:
User.scour(_sort: %w[username email])
```
