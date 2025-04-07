import unittest
from appium import webdriver
from appium.webdriver.common.appiumby import AppiumBy
import time
import re

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

    def test_register_success(self):
        """Kiểm thử đăng ký thành công với Gmail hợp lệ"""
        self.driver.find_element(AppiumBy.ID, "com.example:id/registerButton").click()

        # Nhập thông tin đăng ký
        self.driver.find_element(AppiumBy.ID, "com.example:id/username").send_keys("testuser@gmail.com")
        self.driver.find_element(AppiumBy.ID, "com.example:id/password").send_keys("password123")
        self.driver.find_element(AppiumBy.ID, "com.example:id/registerConfirmButton").click()

        # Kiểm tra thông báo thành công
        success_message = self.driver.find_element(AppiumBy.ID, "com.example:id/successMessage").text
        self.assertEqual(success_message, "Đăng ký thành công")
        time.sleep(2)

    def test_register_failure_invalid_email(self):
        """Kiểm thử đăng ký không thành công với email không hợp lệ"""
        self.driver.find_element(AppiumBy.ID, "com.example:id/registerButton").click()

        # Nhập thông tin đăng ký với email không hợp lệ
        self.driver.find_element(AppiumBy.ID, "com.example:id/username").send_keys("invalid-email")
        self.driver.find_element(AppiumBy.ID, "com.example:id/password").send_keys("password123")
        self.driver.find_element(AppiumBy.ID, "com.example:id/registerConfirmButton").click()

        # Kiểm tra thông báo lỗi khi nhập email không hợp lệ
        error_message = self.driver.find_element(AppiumBy.ID, "com.example:id/errorMessage").text
        self.assertEqual(error_message, "Vui lòng nhập địa chỉ email hợp lệ.")
        time.sleep(2)

    def test_register_failure_empty_fields(self):
        """Kiểm thử đăng ký không thành công với trường thông tin bị bỏ trống"""
        self.driver.find_element(AppiumBy.ID, "com.example:id/registerButton").click()

        # Nhập thông tin không đầy đủ
        self.driver.find_element(AppiumBy.ID, "com.example:id/username").send_keys("")  # Email trống
        self.driver.find_element(AppiumBy.ID, "com.example:id/password").send_keys("")
        self.driver.find_element(AppiumBy.ID, "com.example:id/registerConfirmButton").click()

        # Kiểm tra thông báo lỗi khi trường thông tin bị bỏ trống
        error_message = self.driver.find_element(AppiumBy.ID, "com.example:id/errorMessage").text
        self.assertEqual(error_message, "Vui lòng điền đầy đủ thông tin.")
        time.sleep(2)

    def tearDown(self):
        self.driver.quit()

if __name__ == "__main__":
    unittest.main()
