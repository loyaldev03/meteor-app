# Testing Documentation

## Definitions:
**Unit Testing:** These kind of tests ensure that a single unit of code (a method) works as expected (given an input, it has a predictable output). These tests should be isolated as much as possible. [Source](https://en.wikipedia.org/wiki/Unit_testing)

**Feature Tesing:** A kind of acceptance test, are high-level tests that walk through your entire application ensuring that each of the components work together. They’re written from the perspective of a user clicking around the application and filling in forms. [Source](https://thoughtbot.com/blog/how-we-test-rails-applications#feature-specs)

## Priority To-Do List
1. Change the "functional" folder name to "controllers" so that it is more easily understood.
2. BrowsingTest can be removed since performance_test_help does not exist in Rails 4
3. Several classes in the "integration" folder are improperly named based on the filename
4. Move model tests related to associations and validation to the model folder under the appropriate filename. This may require temporarily changing a unit of the same filename.
5. Unit tests should be broken up and properly renamed to what they are testing.
For example: in unit/campaign_test.rb the facebook and mailchimp section should be their own files and classes. This is because you are really testing TaskHelpers class and not the campaign model.
6. Classes in the lib folder are perfect example for unit tests.
7. Certain methods within models that are not directly related to associations and validation of that model should also be moved or created as unit tests.
8. Review coverage/index.html and write tests for missing controller actions

## Coverage Priority Files
### Controllers Tests
1. app/controllers/admin/agents_controller.rb
1. app/controllers/users_controller.rb
1. app/controllers/clubs_controller.rb
1. app/controllers/credit\_cards\_controller.rb
1. app/controllers/api/tokens_controller.rb
1. app/controllers/club\_cash\_transactions\_controller.rb
1. app/controllers/memberships_controller.rb
1. app/controllers/operations_controller.rb
1. app/controllers/transactions_controller.rb

### Model Tests
1. app/models/gateways/trust_commerce_transaction.rb
1. app/models/product.rb
1. app/models/communication.rb
1. app/models/user.rb

### Unit Tests
1. lib/sac_*/\*
1. lib/campaigns/*
1. lib/validators/*
2. lib/lyris_service.rb

## Guidelines

### What to Unit Test
* app/finders/
* app/helpers/
* app/presenters/
* app/services/

In this case some model method would be refactored into different domain objects. For the immediate future if tests, such as test/unit/campaign\_test.rb, are spilt between test/model and test/unit the model test filename should be MODEL\_test.rb and the unit should be MODEL\_unit\_test.rb if the unit test doesn't have a meaningful name on its own.

### Feature Test Guideline

* Feature tests should be named ROLE\_ACTION\_test.rb, such as user\_changes\_password_test.rb.
* Use scenario titles that describe the success and failure paths.
* Avoid scenario titles that add no information, such as “successfully”.
* Avoid scenario titles that repeat the feature title.
* Create only the necessary records in the database
* Test a happy path and a less happy path but that’s it
* Every other possible path should be tested with Unit or Integration (Controller) tests
* Test what’s displayed on the page, not the internals of ActiveRecord models. For instance, if you want to verify that a record was created, add expectations that its attributes are displayed on the page, not that Model.count increased by one.
* It’s ok to look for DOM elements but don’t abuse it since it makes the tests more brittle
