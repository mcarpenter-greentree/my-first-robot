*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Playwright
Library             RPA.Browser.Selenium
Library             String
Library             RPA.PDF
Library             RPA.RobotLogListener
Library             RPA.Archive
Library             RPA.Tables
Library             OperatingSystem
Library             RPA.Dialogs
Library             RPA.Robocorp.Vault


*** Variables ***
${OUTPUT_DIR}=      ${CURDIR}${/}output
${RECEIPTS_DIR}=    ${OUTPUT_DIR}${/}receipts


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Configure the environment
    ${orders_url}=    Ask for user input
    ${secret}=    Get Secret    bot_sizzle_site_stuff
    Open the robot order website    ${secret}
    ${orders}=    Get Orders    ${orders_url}
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Wait Until Keyword Succeeds    5x    1s    Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}
        ${screenshot}=    Take a screenshot of the robot    ${row}
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts


*** Keywords ***
Configure the environment
    Create Directory    ${OUTPUT_DIR}
    Create Directory    ${RECEIPTS_DIR}

Ask for user input
    Add heading    Enter Orders URL
    Add text input    name=orders_url    label=Orders URL
    ${orders_url}=    Run dialog
    RETURN    ${orders_url}

Open the robot order website
    [Arguments]    ${secret}
    Log    Navigating to ${secret}[username]
    RPA.Browser.Playwright.Open Browser    url=${secret}[password]

Get Orders
    [Arguments]    ${orders_url}
    ${downloaded_file}=    Download    url=${orders_url.orders_url}
    ${orders}=    Read table from CSV    ${downloaded_file.saveAs}
    RETURN    ${orders}

Close the annoying modal
    Click    xpath=//button[contains(.,'Yep')]

Fill the form
    [Arguments]    ${order_row}
    Select Options By    select[id=head]    value    ${order_row}[Head]
    Check Checkbox    id=id-body-${order_row}[Body]
    Type Text    xpath=//label[contains(.,'3. Legs:')]/../input    ${order_row}[Legs]
    Type Text    id=address    ${order_row}[Address]

Preview the robot
    Click    id=preview

Submit the order
    Click    id=order
    Wait For Elements State    id=receipt    timeout=3s

Store the receipt as a PDF file
    [Arguments]    ${order_row}
    ${pdf_file_full_path}=    Set Variable    ${RECEIPTS_DIR}${/}${order_row}[Order number]_Receipt.pdf
    ${robot_receipt_html}=    Get Property    id=receipt    outerHTML
    Html To Pdf    ${robot_receipt_html}    ${pdf_file_full_path}
    RETURN    ${pdf_file_full_path}

Take a screenshot of the robot
    [Arguments]    ${order_row}
    ${screenshot}=    Set Variable    ${RECEIPTS_DIR}${/}${order_row}[Order number]_Robot.png
    Take Screenshot    ${screenshot}    id=robot-preview-image
    RETURN    ${screenshot}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Open Pdf    ${pdf}
    ${files}=    Create List    ${screenshot}
    Add Files To Pdf    ${files}    ${pdf}    append=True
    #Close Pdf    ${pdf}

Go to order another robot
    Click    id=order-another

Create a ZIP file of the receipts
    Archive Folder With Zip    folder=${RECEIPTS_DIR}    archive_name=${OUTPUT_DIR}${/}receipts.zip
