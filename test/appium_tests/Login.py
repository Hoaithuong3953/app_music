import unittest
from appium import webdriver
from appium.webdriver.common.appiumby import AppiumBy
import time

class MobileAppTest(unittest.TestCase):
    def setUp(self):
        desired_caps = {
            "platformName": "Android",
            "deviceName": "emulator-5554",  # Đổi thành ID thiết bị của bạn nếu dùng điện thoại thật
            "appPackage": "com.example.app",  # Đổi thành package của ứng dụng
            "appActivity": ".MainActivity",  # Đổi thành activity chính
            "automationName": "UiAutomator2"
        }
        self.driver = webdriver.Remote("http://localhost:4723/wd/hub", desired_caps)
        self.driver.implicitly_wait(10)

    def test_login_gmail_success(self):
        """Kiểm thử chức năng đăng nhập thành công bằng Gmail"""
        self.driver.find_element(AppiumBy.ID, "com.example:id/loginButton").click()

        # Giả sử ứng dụng sẽ mở màn hình đăng nhập của Google
        self.driver.find_element(AppiumBy.ID, "com.google.android.gms:id/account_name").send_keys("testuser@gmail.com")
        self.driver.find_element(AppiumBy.ID, "com.google.android.gms:id/password").send_keys("password123")
        self.driver.find_element(AppiumBy.ID, "com.google.android.gms:id/sign_in_button").click()

        # Kiểm tra thông báo đăng nhập thành công
        welcome_message = self.driver.find_element(AppiumBy.ID, "com.example:id/welcomeMessage").text
        self.assertEqual(welcome_message, "Chào mừng testuser@gmail.com")
        time.sleep(2)

    def test_login_gmail_failure(self):
        """Kiểm thử chức năng đăng nhập thất bại với Gmail"""
        self.driver.find_element(AppiumBy.ID, "com.example:id/loginButton").click()

        # Giả sử ứng dụng sẽ mở màn hình đăng nhập của Google
        self.driver.find_element(AppiumBy.ID, "com.google.android.gms:id/account_name").send_keys("testuser@gmail.com")
        self.driver.find_element(AppiumBy.ID, "com.google.android.gms:id/password").send_keys("wrongpassword")
        self.driver.find_element(AppiumBy.ID, "com.google.android.gms:id/sign_in_button").click()

        # Kiểm tra thông báo lỗi
        error_message = self.driver.find_element(AppiumBy.ID, "com.google.android.gms:id/error_message").text
        self.assertEqual(error_message, "Mật khẩu không chính xác")
        time.sleep(2)

    def tearDown(self):
        self.driver.quit()

if __name__ == "__main__":
    unittest.main()
