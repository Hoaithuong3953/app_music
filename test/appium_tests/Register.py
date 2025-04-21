import unittest
import time
from appium import webdriver
from appium.options.android import UiAutomator2Options
from appium.webdriver.common.appiumby import AppiumBy
from selenium.common.exceptions import WebDriverException, NoSuchElementException, StaleElementReferenceException, TimeoutException
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
    locale='US',
    noReset=True
)

appium_server_url = 'http://127.0.0.1:4723/wd/hub'

class TestRegister(unittest.TestCase):
    def setUp(self) -> None:
        print("🔄 Đang khởi động Appium driver...")
        try:
            options = UiAutomator2Options().load_capabilities(capabilities)
            self.driver = webdriver.Remote(appium_server_url, options=options)
            time.sleep(5)
            print("✅ Driver đã khởi động thành công.")
        except WebDriverException as e:
            print(f"❌ Lỗi khi khởi động driver: {e}")
            self.driver = None
            raise

        # Chuẩn bị thư mục và file Excel
        self.excel_dir = "result"
        self.excel_file = os.path.join(self.excel_dir, "result_register.xlsx")
        self.init_excel()

    def init_excel(self):
        """Khởi tạo thư mục result và file Excel nếu chưa tồn tại"""
        if not os.path.exists(self.excel_dir):
            os.makedirs(self.excel_dir)
            print(f"✅ Đã tạo thư mục: {self.excel_dir}")

        if not os.path.exists(self.excel_file):
            wb = Workbook()
            ws = wb.active
            ws.title = "Register Results"
            ws.append(["Test Case", "First Name", "Last Name", "Email", "Mobile", "Password", "Address", "Result", "Status", "Timestamp"])
            wb.save(self.excel_file)
        print(f"✅ File Excel: {self.excel_file}")

    def save_to_excel(self, test_case, first_name, last_name, email, mobile, password, address, result, status):
        """Lưu kết quả vào file Excel"""
        try:
            wb = load_workbook(self.excel_file)
            ws = wb["Register Results"]
            timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            ws.append([test_case, first_name, last_name, email, mobile, password, address, result, status, timestamp])
            wb.save(self.excel_file)
            print(f"✅ Đã lưu kết quả vào Excel: {test_case}, {first_name}, {last_name}, {email}, {mobile}, {password}, {address}, {result}, {status}")
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

    def restart_app(self):
        """Khởi động lại ứng dụng nếu thoát"""
        try:
            self.driver.terminate_app('com.example.app_music')
            self.driver.activate_app('com.example.app_music')
            time.sleep(5)
            print("✅ Đã khởi động lại ứng dụng.")
        except Exception as e:
            print(f"❌ Lỗi khi khởi động lại ứng dụng: {e}")
            raise

    def navigate_to_register(self):
        """Điều hướng đến màn hình đăng ký"""
        try:
            signup_nav_button = self.find_element_with_retry(
                AppiumBy.XPATH, '//android.widget.Button[@content-desc="Don\'t have an account? Sign up"]'
            )
            signup_nav_button.click()
            WebDriverWait(self.driver, 15).until(
                EC.presence_of_element_located((AppiumBy.XPATH, '//android.view.View[@content-desc="Create a New Account"]'))
            )
            print("✅ Đã vào màn hình đăng ký.")
        except Exception as e:
            print(f"❌ Lỗi khi điều hướng đến màn hình đăng ký: {e}")
            raise

    def check_register_screen(self):
        """Kiểm tra xem vẫn ở màn hình đăng ký"""
        try:
            WebDriverWait(self.driver, 5).until(
                EC.presence_of_element_located((AppiumBy.XPATH, '//android.view.View[@content-desc="Create a New Account"]'))
            )
            return True
        except:
            print("⚠️ Không còn ở màn hình đăng ký!")
            print("🔍 Page Source khi rời khỏi màn hình:")
            print(self.driver.page_source)
            return False

    def find_element_with_retry(self, by, value, retries=5, wait_seconds=30):
        """Tìm phần tử với cơ chế retry"""
        for attempt in range(retries):
            try:
                element = WebDriverWait(self.driver, wait_seconds).until(
                    EC.element_to_be_clickable((by, value))
                )
                return element
            except (StaleElementReferenceException, TimeoutException):
                print(f"⚠️ Lỗi tìm phần tử tại lần thử {attempt + 1}/{retries}. Thử lại...")
                if not self.check_register_screen():
                    print("🔄 Ứng dụng đã thoát. Quay lại màn hình đăng ký...")
                    self.restart_app()
                    self.navigate_to_register()
                time.sleep(2)
        raise Exception(f"❌ Không thể tìm phần tử sau {retries} lần thử: {by}={value}")

    def input_field_with_retry(self, field_xpath, value, field_name, retries=5, wait_seconds=30, is_password=False):
        """Nhập liệu và kiểm tra với retry"""
        max_nav_attempts = 3
        nav_attempts = 0
        while nav_attempts < max_nav_attempts:
            if not self.check_register_screen():
                print("🔄 Màn hình đăng ký không còn, thử quay lại...")
                self.restart_app()
                self.navigate_to_register()
                nav_attempts += 1
                continue
            for attempt in range(retries):
                try:
                    print(f"🔄 Thử nhập {field_name} lần {attempt + 1}/{retries}...")
                    field = self.find_element_with_retry(AppiumBy.XPATH, field_xpath, retries=retries, wait_seconds=wait_seconds)
                    print(f"✅ Đã tìm thấy trường {field_name}.")
                    WebDriverWait(self.driver, wait_seconds).until(
                        EC.element_to_be_clickable((AppiumBy.XPATH, field_xpath))
                    )
                    field.click()
                    time.sleep(1)
                    field.clear()
                    time.sleep(0.5)
                    # Dùng execute_script thay vì send_keys để tránh Enter
                    self.driver.execute_script('mobile: type', {'elementId': field.id, 'text': value})
                    time.sleep(1)
                    try:
                        self.driver.hide_keyboard()
                    except:
                        pass
                    field_text = field.get_attribute("text")
                    print(f"✅ Đã nhập {field_name}: {field_text}")
                    if not self.check_register_screen():
                        print("🔍 Page Source sau khi nhập liệu:")
                        print(self.driver.page_source)
                        self.fail(f"❌ Đã rời khỏi màn hình đăng ký sau khi nhập {field_name}!")
                    if not is_password:
                        self.assertEqual(field_text, value, f"{field_name} không được nhập đúng!")
                    else:
                        self.assertNotEqual(field_text, "", f"{field_name} không được nhập!")
                    return
                except (StaleElementReferenceException, TimeoutException, WebDriverException) as e:
                    print(f"⚠️ Lỗi khi nhập {field_name} tại lần thử {attempt + 1}/{retries}: {e}")
                    print("🔍 Page Source khi gặp lỗi:")
                    print(self.driver.page_source)
                    time.sleep(2)
            self.fail(f"❌ Không thể nhập {field_name} sau {retries} lần thử.")
        self.fail(f"❌ Không thể quay lại màn hình đăng ký sau {max_nav_attempts} lần thử.")

    def scroll_to_element(self):
        """Cuộn để tìm nút Sign Up"""
        try:
            self.driver.hide_keyboard()
            self.driver.find_element(AppiumBy.ANDROID_UIAUTOMATOR,
                                     'new UiScrollable(new UiSelector().scrollable(true)).scrollIntoView('
                                     'new UiSelector().description("Sign Up"))')
            print("✅ Đã cuộn đến nút Sign Up.")
        except Exception as e:
            print(f"⚠️ Lỗi khi cuộn: {e}")

    def test_register_success(self) -> None:
        """Test đăng ký thành công với thông tin hợp lệ"""
        if not self.driver:
            self.fail("❌ Driver chưa được khởi động.")

        # Lưu trữ thông tin để ghi vào Excel
        first_name = "Khai"
        last_name = "Black"
        email = f"khaiblack{int(time.time())}@gmail.com"
        mobile = "0987654321"
        password = "123456"
        address = "123 Le Loi, Hai Chau, Da Nang"

        try:
            print("Page Source của MainActivity:")
            print(self.driver.page_source)

            # Điều hướng đến màn hình đăng ký
            self.navigate_to_register()
            print("Page Source sau khi vào màn hình đăng ký:")
            print(self.driver.page_source)

            # Nhập thông tin
            self.input_field_with_retry('//android.widget.EditText[@index="3"]', first_name, "First Name")
            print("🔍 Page Source sau khi nhập First Name:")
            print(self.driver.page_source)
            if not self.check_register_screen():
                self.fail("❌ Ứng dụng đã thoát khỏi màn hình đăng ký sau khi nhập First Name!")

            self.input_field_with_retry('//android.widget.EditText[@index="4"]', last_name, "Last Name")
            self.input_field_with_retry('//android.widget.EditText[@index="5"]', email, "Email")
            self.input_field_with_retry('//android.widget.EditText[@index="6"]', mobile, "Mobile")
            self.input_field_with_retry('//android.widget.EditText[@index="7"]', password, "Password", is_password=True)
            self.input_field_with_retry('//android.widget.EditText[@index="8"]', address, "Address")

            # In Page Source trước khi tìm nút Sign Up
            print("🔍 Page Source trước khi tìm nút Sign Up:")
            print(self.driver.page_source)

            # Cuộn đến nút Sign Up
            self.scroll_to_element()

            # Tìm và nhấn nút Sign Up
            signup_button = self.find_element_with_retry(
                AppiumBy.XPATH, '//android.widget.Button[@content-desc="Sign Up"]'
            )
            signup_button.click()
            print("✅ Đã nhấn nút Sign Up")
            time.sleep(15)

            # Kiểm tra thông báo lỗi
            try:
                error_message = WebDriverWait(self.driver, 12).until(
                    EC.visibility_of_element_located(
                        (AppiumBy.XPATH, "//*[contains(@content-desc, 'không thành công')]")
                    )
                )
                print("🔍 Page Source khi phát hiện lỗi:")
                print(self.driver.page_source)
                result = error_message.get_attribute('content-desc')
                status = "FAILED"
                self.fail(f"❌ Đăng ký thất bại: {result}")
            except TimeoutException:
                print("✅ Không có thông báo lỗi, kiểm tra chuyển màn hình...")

            # In Page Source sau khi nhấn Sign Up
            print("🔍 Page Source sau khi nhấn Sign Up:")
            print(self.driver.page_source)

            # Kiểm tra chuyển sang MainScreen
            main_screen_element = WebDriverWait(self.driver, 20).until(
                EC.presence_of_element_located(
                    (AppiumBy.XPATH, '//*[contains(@text, "Music") or contains(@content-desc, "Music")]')
                )
            )
            self.assertTrue(main_screen_element.is_displayed(), "Không chuyển được sang màn hình chính!")
            result = "Đăng ký thành công và chuyển sang màn hình chính"
            status = "PASSED"
            print("✅ Đăng ký thành công và chuyển sang màn hình chính!")

            # Lưu kết quả vào Excel
            self.save_to_excel(
                test_case="Register Success",
                first_name=first_name,
                last_name=last_name,
                email=email,
                mobile=mobile,
                password=password,
                address=address,
                result=result,
                status=status
            )

        except NoSuchElementException as e:
            print("🔍 In cấu trúc giao diện để debug:")
            print(self.driver.page_source)
            self.save_to_excel(
                test_case="Register Success",
                first_name=first_name,
                last_name=last_name,
                email=email,
                mobile=mobile,
                password=password,
                address=address,
                result=f"Lỗi: {str(e)}",
                status="FAILED"
            )
            self.fail(f"❌ Không tìm thấy phần tử: {e}")
        except Exception as e:
            print("🔍 In cấu trúc giao diện để debug:")
            print(self.driver.page_source)
            self.save_to_excel(
                test_case="Register Success",
                first_name=first_name,
                last_name=last_name,
                email=email,
                mobile=mobile,
                password=password,
                address=address,
                result=f"Lỗi: {str(e)}",
                status="FAILED"
            )
            self.fail(f"❌ Lỗi không xác định: {e}")

if __name__ == '__main__':
    unittest.main(verbosity=2)