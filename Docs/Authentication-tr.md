# Authentication
Turbolinks iOS app'te authentication işlemini yönetmenin iki yolu var. Öncelikle, bir web view üzerinden kullanıcıyı doğrulayacak ve cookie'lere güveneceksiniz. Framework herhangi bir kimlik doğrulama işlemi oluşturmanıza veya api kullanmanıza olanak sağlamıyor. Bu tamamen her uygulamaya bağlıdır ve uygulama ayarlarına göre değişir.

## Cookies
Uygulamanızın native koddan kimliği doğrulanmış herhangi bir ağ isteği göndermesi gerekmiyorsa, bir web tarayısında olduğu gibi çerezleri kullanabilirsiniz. Kullanıcı kimliği doğrulandığında uygun çerezleri ayarlayın ve kalıcı olduklarından emin olun. Burada oturum çerezleri kullanıldığında kaybolabilir. WKWebView bu çerezlerin uygulama başlatmaları sırasında uygun şekilde diske kalmasını otomatik olarak sağlar.


## Native & Web
Hem web'den hem de native koddan kimliği doğrulanmış ağ istekleri yapmanız gerekiyorsa, biraz daha karmaşık, ve uygulanıza bağlı. Native olarak kimlik doğrulaması yapabilir ve bir şekilde bu kimlik bilgilerini web görünümüne verebilir veya web'de kimlik doğrulamasını yapabilir ve bu kimlik bilgilerini native kaynaklara gönderebilirsiniz. Orada özel bir önerimiz yok, ancak bunu iOS için Basecamp 3'te nasıl kullanmaya karar verdiğimizi söyleyebiliriz.


### Basecamp 3
Basecamp 3 için tamamen native olarak kimlik doğrulaması yapıyoruz ve API'mızdan bir OAuth token alıyoruz. Daha sonra bu kodu kullanıcının keychain'inde güvenli bir şekilde sürdürüyoruz.Bu OAuth token, NSURLSession'da bir başlık ayarlayarak tüm ağ istekleri için kullanılır. Bu OAuth token tüm native ekranlar ve uzantılar(extensions) için kullanılır (bugün paylaş, izle).

Uygulamamıza ilk defa web görüntüsü yüklediğinizde, Turbolinks'ten 401 alıyoruz. Bu cevabı, web görünümü için uygun çerezleri ayarlayan OAuth token kullanarak, sunucumuzdaki bir uç noktaya gizli bir WKWebView'da özel bir istek yaparak hallederiz.

Bu stratejinin anahtarı, OAuth başlığını kullanarak bir NSURLRequest oluşturmaktır, ve kimlik doğrulama isteği için webView.loadRequest(request) adlı web görünümünü yüklemek için bunu kullanın. Web görünümü Turbolinks web görünümünden farklıysa, çerezlerin paylaşılması için aynı WKProcessPool'u kullandıklarından emin olmanız gerekir.
