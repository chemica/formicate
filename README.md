# Formicate

Formicate is a generalised implementation of the 'form object' pattern. Form objects allow us to collect behaviour
relating to particular forms into their own objects, thus handling validation and data manipulation/cleansing without
dirtying up the controller or model. Form objects can be used by form builders instead of directly using ActiveRecord
models.

The advantages of form objects include:

 - Separation of concerns: The form object encapsulates the behaviour connected to submitting a form, freeing the
 controller or model from having to carry it around. It also acts as a level of indirection between the controller and
the view, allowing the model internals to change without the view being affected.
 - Reusability: Form objects can be applied to multiple controllers or poymorphically handle multiple models if needed.
Formicate also includes patterns for reusing slices of form object behaviour across forms.
 - No more attr_accessible or strong params: As the form object is defined with a list of accessors, it is impossible
for a form to be hacked in such a way as to set unwelcome fields on a model.
 - No more nested forms: Anything you like can be passed in to a form object during initialization. As both the
initialization and processing steps are left completely open, a form object can provide fields relating to multiple
models if required. This cleans up the views to a huge extent and further protects the views from changes to models.


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'formicate'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install formicate


## Usage:

Create a your form object class inheriting from the Formicate::Base class.

```ruby
class MyForm < Formicate::Base
```

Use form_fields in the class definition to register form fields:

```ruby
form_fields :original_password, :new_password, :password_confirmation, :date
```

Form fields will behave like ActiveModel fields. They will become accessors and after form processing will contain the
'cleaned' forms of the values passed in through params. Cleaning performs any operations you may want to apply to data
to make it safer or easier to handle. This could be parsing dates or sanitizing strings. If no cleaner is specified,
the data will be passed from the params to the accessors unchanged.

```ruby
def clean_data
  self.date = parse_date(self.date)
end
```

Add ActiveModel validations:

```ruby
validate :verify_original_password
validates_presence_of :original_password, :new_password
validates_confirmation_of :new_password
validates_length_of :new_password, minimum: 6

def verify_original_password
  unless @user.authenticate(original_password)
    errors.add :original_password, "is not correct"
  end
end
```

Add an initialiser:

```ruby
def after_initialize(user)
  @user = user
end
```

An initialiser will always be run on creation of the form. If you pass any parameters to the `new` method of the form
object class, they will be passed through to the initializer:

```ruby
MyForm.new(current_user)
```

Add the optional processing methods: process_valid/process_invalid/process_always. These will be called after
after the form `process` method, conditional on the forms validity.

```ruby
def process_valid(params)
  # Add any code that needs to be run if the form is valid
  @user.password = new_password
  @user.save!
end

attr_accessor :drop_down_values
def process_always(params)
  # Add any code that needs to be run every time
  self.drop_down_values = [['yes', 1], ['no', 0]]
end
```

In the relevant controller/facade/service object:

```ruby
def new
  @password_form = PasswordForm.new(current_user)
end

def create
  @password_form = PasswordForm.new(current_user)
  if @password_form.process(params) # process method returns true or false based on form validity.
    redirect_to current_user, notice: "Successfully changed password."
  else
    render "new"
  end
end
```

You can use ActiveModel features like `valid?` and `errors`:

```ruby
@password_form.errors.full_messages
```

If you want default values for your form, add them to the class definition:

```ruby
defaults date: Time.now
```

In the view, use a form builder as if the form object was a model.

```ruby
<%= form_for @password_form do |f| %>
  Original Password :     <%= f.password_field :original_password %><br />
  New Password :          <%= f.password_field :new_password %><br />
  Password Confirmation : <%= f.password_field :password_confirmation %><br />
  Date :                  <%= f.text_field :date %><br />
  <%= f.submit %>
<% end %>
```

It also works with form builders and gems such as Formtastic or Simple Form:

```ruby
<%= simple_form_for @password_form do |f| %>
  <%= f.input :original_password %>
  <%= f.input :new_password, hint: 'No special characters.' %>
  <%= f.input :password_confirmation %>
  <%= f.input :date, as: date %>
  <%= f.button :submit %>
<% end %>
```

If you want to access the original parameters, you can

## DRYing things up

If you find that you're implementing the same form features over and over again, you may want something that mirrors the
behaviour of your partials in the templates. If, for example, you found yourself using date behaviour across multiple
forms you could put date behaviour into an ActiveSupport Concern. If you're not using Rails or you don't like concerns,
just use a plain old Ruby module or a Concern-style library like Augmentations. Here I'm using Augmentations:

https://github.com/chemica/augmentations-gem

```ruby
module FormAugmentations::HasDate
  augmentation do

    form_fields :date

    validate :date_is_parsable

    private

      def has_date_cleaner
        self.date = parse_date(self.date)
      end
      add_cleaner :has_date_cleaner

      def parse_date(date)
        @parsed_date ||= if date.present?
          begin
            DateTime.parse(date.to_s)
          rescue ArgumentError
            nil
          end
        end
      end

      def date_is_parsable
        errors.add :date, 'is_invalid' unless parse_date(params[:date])
      end
  end
end
```

Note that in order for the date cleaner to be called during validation you must register it with:

```ruby
add_cleaner :has_date_cleaner
```

You can register processors in a similar fashion:

```ruby
def has_date_processor
  ...
end
add_processor :has_date_processor, :valid
```

`:valid` can, of course, be swapped out for `:invalid` and `:always`

Cleaners and validators from modules must be registered in this way as otherwise they would be overwritten by the
concrete form class. (MyForm in the examples.)

Now in your form:

```ruby
class MyForm < Formicate::Base
  augment FormAugmentations::HasDate
end
```


## Contributing

1. Fork it ( https://github.com/[my-github-username]/formicate/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Write some tests against your new functionality or bug fix. No tests, no pull.
4. Commit your changes (`git commit -am 'Add some feature'`)
5. Ensure the tests pass for all relevant ActiveModel and Ruby versions in Travis.
6. Push to the branch (`git push origin my-new-feature`)
7. Create a new Pull Request
