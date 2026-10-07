Pod::Spec.new do |s|
  s.name             = 'mercadopago'
  s.version          = '0.1.0'
  s.summary          = 'Official MercadoPago SDK for Flutter.'
  s.description      = <<-DESC
Official MercadoPago SDK for Flutter — card tokenization, payment methods,
installments, and PCI input widgets for Latin America.
                       DESC
  s.homepage         = 'https://github.com/mercadopago/sdk-flutter'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'MercadoPago' => 'developers@mercadopago.com' }
  s.source           = { :path => '.' }
  s.source_files        = 'Classes/**/*'
  s.resource_bundles    = {
    'mercadopago_privacy' => ['Resources/PrivacyInfo.xcprivacy']
  }
  s.dependency 'Flutter'
  s.platform         = :ios, '13.0'
  s.swift_version    = '5.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
end
