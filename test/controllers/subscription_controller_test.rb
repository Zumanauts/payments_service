require "test_helper"

class SubscriptionControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    get subscription_create_url
    assert_response :success
  end

  test "should get process" do
    get subscription_process_url
    assert_response :success
  end
end
