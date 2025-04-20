import unittest
import time
from appium import webdriver
from appium.options.android import UiAutomator2Options
from appium.webdriver.common.appiumby import AppiumBy
from selenium.common.exceptions import WebDriverException, NoSuchElementException
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from openpyxl import Workbook, load_workbook
from datetime import datetime
import os

capabilities = dict(
    platformName='Android',
    automationName='uiautomator2',
    deviceName='emulator-5554',
    appPackage='com.example.app_music',
    appActivity='.MainActivity',
    language='en',
    locale='US'
)

appium_server_url = 'http://127.0.0.1:4723/wd/hub'

class TestLoginFunction(unittest.TestCase):
    def setUp(self) -> None:
        print("🔄 Đang khởi động Appium driver...")
        try:
            options = UiAutomator2Options().load_capabilities(capabilities)
            self.driver = webdriver.Remote(appium_server_url, options=options)
            time.sleep(5)  # Chờ ứng dụng khởi động
            print("✅ Driver đã khởi động thành công.")
        except WebDriverException as e:
            print(f"❌ Lỗi khi khởi động driver: {e}")
            self.driver = None
            raise

        # Chuẩn bị thư mục và file Excel
        self.excel_dir = "result"
        self.excel_file = os.path.join(self.excel_dir, "result_login.xlsx")
        self.init_excel()

    def init_excel(self):
        """Khởi tạo thư mục result và file Excel nếu chưa tồn tại"""
        if not os.path.exists(self.excel_dir):
            os.makedirs(self.excel_dir)
            print(f"✅ Đã tạo thư mục: {self.excel_dir}")

        if not os.path.exists(self.excel_file):
            wb = Workbook()
            ws = wb.active
            ws.title = "Login Results"
            ws.append(["Test Case", "Email", "Password", "Result", "Status", "Timestamp"])
            wb.save(self.excel_file)
        print(f"✅ File Excel: {self.excel_file}")

    def save_to_excel(self, test_case, email, password, result, status):
        """Lưu kết quả vào file Excel"""
        try:
            wb = load_workbook(self.excel_file)
            ws = wb["Login Results"]
            timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            ws.append([test_case, email, password, result, status, timestamp])
            wb.save(self.excel_file)
            print(f"✅ Đã lưu kết quả vào Excel: {test_case}, {email}, {password}, {result}, {status}")
        except Exception as e:
            print(f"⚠️ Lỗi khi lưu vào Excel: {e}")

    def tearDown(self) -> None:
        if self.driver:
            try:
                self.driver.quit()
                print("✅ Đã đóng driver.")
            except WebDriverException as e:
                print(f"⚠️ Không thể đóng driver: {e}")
        else:
            print("⚠️ Không có driver để đóng.")

    def scroll_to_element(self):
        """Cuộn để tìm nút Login dựa trên content-desc"""
        try:
            self.driver.find_element(AppiumBy.ANDROID_UIAUTOMATOR,
                                     'new UiScrollable(new UiSelector().scrollable(true)).scrollIntoView('
                                     'new UiSelector().description("Login"))')
            print("✅ Đã cuộn để tìm nút Login.")
        except Exception as e:
            print(f"⚠️ Lỗi khi cuộn: {e}")

    def test_successful_login(self):
        if not self.driver:
            self.fail("❌ Driver chưa được khởi động.")
        try:
            # Tìm và nhập email
            email_field = WebDriverWait(self.driver, 10).until(
                EC.presence_of_all_elements_located((AppiumBy.CLASS_NAME, "android.widget.EditText"))
            )[0]  # Index 0 cho email
            email_field.click()
            email_field.clear()
            email_field.send_keys("khai@gmail.com")
            time.sleep(1)
            email_text = email_field.get_attribute("text")
            print(f"✅ Đã nhập email: {email_text}")
            self.assertEqual(email_text, "khai@gmail.com", "Email không được nhập đúng!")

            # Tìm và nhập mật khẩu
            password_field = WebDriverWait(self.driver, 10).until(
                EC.presence_of_all_elements_located((AppiumBy.CLASS_NAME, "android.widget.EditText"))
            )[1]  # Index 1 cho password
            password_field.click()
            password_field.clear()
            password_field.send_keys("123456")
            time.sleep(1)
            password_text = password_field.get_attribute("text")
            print(f"✅ Đã nhập mật khẩu: {password_text}")
            self.assertEqual(len(password_text), len("123456"), "Độ dài mật khẩu không khớp!")

            # Ẩn bàn phím và cuộn đến nút Login
            self.driver.hide_keyboard()
            time.sleep(1)
            self.scroll_to_element()
            login_button = WebDriverWait(self.driver, 10).until(
                EC.element_to_be_clickable((AppiumBy.XPATH, "//android.widget.Button[@content-desc='Login']"))
            )
            login_button.click()
            print("✅ Đã nhấn nút Login.")
            time.sleep(5)

            # Kiểm tra thông báo lỗi
            try:
                error_message = WebDriverWait(self.driver, 5).until(
                    EC.visibility_of_element_located(
                        (AppiumBy.XPATH, "//*[@content-desc[contains(., 'Đăng nhập không thành công')]]")
                    )
                )
                result = error_message.get_attribute('content-desc')
                status = "FAILED"
                self.fail(f"❌ Đăng nhập thất bại với thông tin đúng: {result}")
            except:
                result = "Đăng nhập thành công (không có thông báo lỗi)"
                status = "PASSED"
                print("✅ Đăng nhập thành công (không có thông báo lỗi)!")

            # Lưu kết quả vào Excel
            self.save_to_excel(
                test_case="Successful Login",
                email="khai@gmail.com",
                password="123456",
                result=result,
                status=status
            )

        except NoSuchElementException as e:
            print("🔍 In cấu trúc giao diện để debug:")
            print(self.driver.page_source)
            self.save_to_excel(
                test_case="Successful Login",
                email="khai@gmail.com",
                password="123456",
                result=f"Lỗi: {str(e)}",
                status="FAILED"
            )
            self.fail(f"❌ Không tìm thấy phần tử cần thiết: {e}")
        except Exception as e:
            print("🔍 In cấu trúc giao diện để debug:")
            print(self.driver.page_source)
            self.save_to_excel(
                test_case="Successful Login",
                email="khai@gmail.com",
                password="123456",
                result=f"Lỗi: {str(e)}",
                status="FAILED"
            )
            self.fail(f"❌ Lỗi không xác định: {e}")

    def test_failed_login(self):
        if not self.driver:
            self.fail("❌ Driver chưa được khởi động.")
        try:
            # Tìm và nhập email
            email_field = WebDriverWait(self.driver, 10).until(
                EC.presence_of_all_elements_located((AppiumBy.CLASS_NAME, "android.widget.EditText"))
            )[0]  # Index 0 cho email
            email_field.click()
            email_field.clear()
            email_field.send_keys("wrong@example.com")
            time.sleep(1)
            email_text = email_field.get_attribute("text")
            print(f"✅ Đã nhập email sai: {email_text}")
            self.assertEqual(email_text, "wrong@example.com", "Email sai không được nhập đúng!")

            # Tìm và nhập mật khẩu
            password_field = WebDriverWait(self.driver, 10).until(
                EC.presence_of_all_elements_located((AppiumBy.CLASS_NAME, "android.widget.EditText"))
            )[1]  # Index 1 cho password
            password_field.click()
            password_field.clear()
            password_field.send_keys("wrongpassword")
            time.sleep(1)
            password_text = password_field.get_attribute("text")
            print(f"✅ Đã nhập mật khẩu sai: {password_text}")
            self.assertEqual(len(password_text), len("wrongpassword"), "Độ dài mật khẩu sai không khớp!")

            # Ẩn bàn phím và cuộn đến nút Login
            self.driver.hide_keyboard()
            time.sleep(1)
            self.scroll_to_element()
            login_button = WebDriverWait(self.driver, 10).until(
                EC.element_to_be_clickable((AppiumBy.XPATH, "//android.widget.Button[@content-desc='Login']"))
            )
            login_button.click()
            print("✅ Đã nhấn nút Login.")
            time.sleep(3)

            # Kiểm tra thông báo lỗi
            error_message = WebDriverWait(self.driver, 10).until(
                EC.visibility_of_element_located(
                    (AppiumBy.XPATH, "//*[@content-desc[contains(., 'Đăng nhập không thành công')]]")
                )
            )
            self.assertTrue(error_message.is_displayed(), "Không hiển thị lỗi khi đăng nhập sai.")
            result = error_message.get_attribute('content-desc')
            status = "PASSED"
            print("✅ Đăng nhập thất bại như mong đợi.")

            # Lưu kết quả vào Excel
            self.save_to_excel(
                test_case="Failed Login",
                email="wrong@example.com",
                password="wrongpassword",
                result=result,
                status=status
            )

        except NoSuchElementException as e:
            print("🔍 In cấu trúc giao diện để debug:")
            print(self.driver.page_source)
            self.save_to_excel(
                test_case="Failed Login",
                email="wrong@example.com",
                password="wrongpassword",
                result=f"Lỗi: {str(e)}",
                status="FAILED"
            )
            self.fail(f"❌ Không tìm thấy phần tử: {e}")
        except Exception as e:
            print("🔍 In cấu trúc giao diện để debug:")
            print(self.driver.page_source)
            self.save_to_excel(
                test_case="Failed Login",
                email="wrong@example.com",
                password="wrongpassword",
                result=f"Lỗi: {str(e)}",
                status="FAILED"
            )
            self.fail(f"❌ Lỗi không xác định: {e}")

if __name__ == "__main__":
    unittest.main(verbosity=2)