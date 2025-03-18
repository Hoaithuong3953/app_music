import unittest
import time
from appium import webdriver
from appium.options.android import UiAutomator2Options

# Cấu hình kết nối Appium
capabilities = dict(
    platformName='Android',
    automationName='uiautomator2',
    deviceName='emulator-5554',  # Thay đổi nếu dùng thiết bị khác
    appPackage='com.example.app_music',  # Thay đổi tên package ứng dụng của bạn
    appActivity='.MainActivity',  # Thay đổi activity tương ứng với ứng dụng
    language='en',
    locale='US'
)

appium_server_url = 'http://127.0.0.1:4723/wd/hub'

class TestOpenApp(unittest.TestCase):
    def setUp(self) -> None:
        """Khởi động Appium và mở ứng dụng"""
        self.driver = webdriver.Remote(appium_server_url, options=UiAutomator2Options().load_capabilities(capabilities))
        time.sleep(5)  # Chờ 5 giây để đảm bảo ứng dụng mở thành công

    def tearDown(self) -> None:
        """Đóng ứng dụng sau khi test xong"""
        if self.driver:
            self.driver.quit()
            print("✅ Ứng dụng đã đóng.")

    def test_open_app(self) -> None:
        """Test mở ứng dụng thành công"""
        print("✅ Ứng dụng đã mở thành công!")
        self.assertTrue(True)  # Test luôn Pass vì chỉ cần mở ứng dụng

if __name__ == '__main__':
    unittest.main()
