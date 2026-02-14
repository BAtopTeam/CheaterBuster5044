import Foundation

enum LinksEnum {
    case privacy, terms, share, support
    
    var link: String {
        switch self {
            case .privacy:  "https://docs.google.com/document/d/1tSby-JSebI8ptEa4xqG-YnyvXyBryTSHTM_ESI_xRQA/edit?usp=sharing"
            case .terms:    "https://docs.google.com/document/d/1HGALVD_R0tOJnizR6Wjwil_d5Cm5imfsNfQfXtZcSCc/edit?usp=sharing"
            case .share:    "https://apps.apple.com/us/app/digital-compass-ai-checker/id6759000863"
            case .support:  "https://forms.gle/xB3BxUcbNfhZGe6j9"
        }
    }
}
