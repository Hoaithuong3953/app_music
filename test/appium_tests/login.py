import unittest
import time
from appium import webdriver
from appium.options.android import UiAutomator2Options
from appium.webdriver.common.appiumby import AppiumBy
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException

# Cấu hình kết nối Appium
capabilities = dict(
    platformName='Android',
    automationName='uiautomator2',
    deviceName='emulator-5554',
    app='D:/University/Year3/KiemThuPhanMem2/project/app_music/build/app/outputs/flutter-apk/app-debug.apk',
    appPackage='com.example.app_music',
    appActivity='.MainActivity',
    language='en',
    locale='US',
    noReset=False,
    fullReset=False,
    fastReset=True
)

appium_server_url = 'http://127.0.0.1:4723/wd/hub'

class TestLoginFunction(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        """Khởi động Appium và mở ứng dụng một lần cho tất cả các test"""
        cls.driver = webdriver.Remote(appium_server_url, options=UiAutomator2Options().load_capabilities(capabilities))
        cls.wait = WebDriverWait(cls.driver, 20)  # Tăng thời gian chờ lên 20 giây
        print("✅ Ứng dụng đã mở một lần cho tất cả các test.")

    @classmethod
    def tearDownClass(cls) -> None:
        """Đóng ứng dụng sau khi tất cả các test hoàn tất"""
        if cls.driver:
            cls.driver.quit()
            print("✅ Ứng dụng đã đóng sau khi tất cả các test hoàn tất.")

    def setUp(self) -> None:
        """Reset ứng dụng trước mỗi test bằng cách đóng và mở lại"""
        self.driver.terminate_app('com.example.app_music')
        self.driver.activate_app('com.example.app_music')
        print("✅ Đã reset ứng dụng trước test (đóng và mở lại).")

    def test_1_failed_login(self) -> None:
        """Test đăng nhập thất bại với thông tin không hợp lệ"""
        # Kiểm tra xem có đang ở LoginScreen không
        try:
            self.wait.until(EC.presence_of_element_located(
                (AppiumBy.ACCESSIBILITY_ID, "login_button")
            ))
            print("✅ Đã ở LoginScreen, sẵn sàng cho test đăng nhập thất bại.")
        except TimeoutException:
            print("❌ Không ở LoginScreen, kiểm tra trạng thái ứng dụng.")
            print("🔍 Kiểm tra giao diện hiện tại:")
            elements = self.driver.find_elements(AppiumBy.CLASS_NAME, "android.widget.TextView")
            for element in elements:
                text = element.text or "Không có text"
                content_desc = element.get_attribute('content-desc') or "Không có content-desc"
                print(f"Text: '{text}', Content-desc: '{content_desc}'")
            raise

        email_field = self.wait.until(EC.presence_of_element_located(
            (AppiumBy.XPATH, '//android.widget.EditText[1]')
        ))
        email_field.clear()
        email_field.send_keys("wrong@example.com")
        email_value = email_field.text
        print(f"✅ Đã nhập email không hợp lệ: '{email_value}'")

        password_field = self.wait.until(EC.presence_of_element_located(
            (AppiumBy.XPATH, '//android.widget.EditText[2]')
        ))
        password_field.clear()
        password_field.send_keys("wrongpassword")
        password_value = password_field.text
        print(f"✅ Đã nhập mật khẩu không hợp lệ: '{password_value}'")

        login_button = self.wait.until(EC.element_to_be_clickable(
            (AppiumBy.ACCESSIBILITY_ID, "login_button")
        ))
        login_button.click()
        print("✅ Đã nhấn nút Login tại thời điểm: ", time.strftime("%H:%M:%S"))

        # Kiểm tra thông báo lỗi
        try:
            error_message = self.wait.until(EC.presence_of_element_located(
                (AppiumBy.ACCESSIBILITY_ID, "error_message")
            ))
            error_text = error_message.text or "Không có text hiển thị"
            print(f"✅ Thông báo lỗi: '{error_text}' tại thời điểm: ", time.strftime("%H:%M:%S"))
            self.assertTrue(error_message.is_displayed(), "Không hiển thị thông báo lỗi!")
            self.assertIn(error_text, ["Email not found", "Invalid password", "Please enter email and password", "Login failed"], "Thông báo lỗi không đúng!")
            print("✅ Đăng nhập thất bại như kỳ vọng, thông báo lỗi hiển thị!")
        except TimeoutException:
            print("❌ Không tìm thấy thông báo lỗi tại thời điểm: ", time.strftime("%H:%M:%S"))
            print("🔍 Kiểm tra giao diện hiện tại:")
            elements = self.driver.find_elements(AppiumBy.CLASS_NAME, "android.widget.TextView")
            for element in elements:
                text = element.text or "Không có text"
                content_desc = element.get_attribute('content-desc') or "Không có content-desc"
                print(f"Text: '{text}', Content-desc: '{content_desc}'")
            raise

    def test_2_successful_login(self) -> None:
        """Test đăng nhập thành công với thông tin hợp lệ"""
        # Kiểm tra xem có đang ở LoginScreen không
        try:
            self.wait.until(EC.presence_of_element_located(
                (AppiumBy.ACCESSIBILITY_ID, "login_button")
            ))
            print("✅ Đã ở LoginScreen, sẵn sàng cho test đăng nhập thành công.")
        except TimeoutException:
            print("❌ Không ở LoginScreen, kiểm tra trạng thái ứng dụng.")
            print("🔍 Kiểm tra giao diện hiện tại:")
            elements = self.driver.find_elements(AppiumBy.CLASS_NAME, "android.widget.TextView")
            for element in elements:
                text = element.text or "Không có text"
                content_desc = element.get_attribute('content-desc') or "Không có content-desc"
                print(f"Text: '{text}', Content-desc: '{content_desc}'")
            raise

        # Kiểm tra không có thông báo lỗi trước khi đăng nhập
        short_wait = WebDriverWait(self.driver, 3)
        try:
            short_wait.until(EC.presence_of_element_located(
                (AppiumBy.ACCESSIBILITY_ID, "error_message")
            ))
            print("❌ Có thông báo lỗi trước khi đăng nhập, trạng thái giao diện không đúng!")
            raise AssertionError("Có thông báo lỗi trước khi đăng nhập!")
        except TimeoutException:
            print("✅ Không có thông báo lỗi trước khi đăng nhập, trạng thái giao diện đúng.")

        email_field = self.wait.until(EC.presence_of_element_located(
            (AppiumBy.XPATH, '//android.widget.EditText[1]')
        ))
        email_field.clear()
        email_field.send_keys("thuong@gmail.com")
        email_value = email_field.text
        print(f"✅ Đã nhập email: '{email_value}'")

        password_field = self.wait.until(EC.presence_of_element_located(
            (AppiumBy.XPATH, '//android.widget.EditText[2]')
        ))
        password_field.clear()
        password_field.send_keys("123456")
        password_value = password_field.text
        print(f"✅ Đã nhập mật khẩu: '{password_value}'")

        login_button = self.wait.until(EC.element_to_be_clickable(
            (AppiumBy.ACCESSIBILITY_ID, "login_button")
        ))
        login_button.click()
        print("✅ Đã nhấn nút Login tại thời điểm: ", time.strftime("%H:%M:%S"))

        # Kiểm tra đã chuyển hướng sang MainScreen
        try:
            self.wait.until(EC.presence_of_element_located(
                (AppiumBy.ACCESSIBILITY_ID, "Hi, Thuong")
            ))
            print("✅ Đã chuyển hướng sang MainScreen tại thời điểm: ", time.strftime("%H:%M:%S"))
            print("✅ Đăng nhập thành công như kỳ vọng!")
        except TimeoutException:
            print("❌ Không chuyển hướng sang MainScreen tại thời điểm: ", time.strftime("%H:%M:%S"))
            # Nếu không chuyển hướng, kiểm tra xem có thông báo lỗi không
            try:
                short_wait = WebDriverWait(self.driver, 5)
                error_message = short_wait.until(EC.presence_of_element_located(
                    (AppiumBy.ACCESSIBILITY_ID, "error_message")
                ))
                error_text = error_message.text or "Không có text hiển thị"
                print(f"❌ Đăng nhập thất bại, thông báo lỗi xuất hiện tại thời điểm: {time.strftime('%H:%M:%S')}")
                print(f"Thông báo lỗi: '{error_text}'")
                print("🔍 Kiểm tra giao diện hiện tại:")
                elements = self.driver.find_elements(AppiumBy.CLASS_NAME, "android.widget.TextView")
                for element in elements:
                    text = element.text or "Không có text"
                    content_desc = element.get_attribute('content-desc') or "Không có content-desc"
                    print(f"Text: '{text}', Content-desc: '{content_desc}'")
                self.fail("Lỗi: Đăng nhập thất bại, thông báo lỗi xuất hiện!")
            except TimeoutException:
                print("❌ Không có thông báo lỗi tại thời điểm: ", time.strftime("%H:%M:%S"))
                print("🔍 Kiểm tra giao diện hiện tại:")
                elements = self.driver.find_elements(AppiumBy.CLASS_NAME, "android.widget.TextView")
                for element in elements:
                    text = element.text or "Không có text"
                    content_desc = element.get_attribute('content-desc') or "Không có content-desc"
                    print(f"Text: '{text}', Content-desc: '{content_desc}'")
                self.fail("Lỗi: Không chuyển hướng sang MainScreen và cũng không có thông báo lỗi!")

if __name__ == '__main__':
    unittest.main()