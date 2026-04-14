// 卡牌抽取说明弹窗
import React, { useState, useEffect } from 'react';

interface CardDrawGuideProps {
  cardType: string;
  onClose?: () => void;
  autoHideMs?: number;
}

export const CardDrawGuide: React.FC<CardDrawGuideProps> = ({
  cardType,
  onClose,
  autoHideMs = 5000,
}) => {
  const [visible, setVisible] = useState(true);

  useEffect(() => {
    if (autoHideMs > 0) {
      const t = setTimeout(() => {
        setVisible(false);
        setTimeout(() => onClose?.(), 400);
      }, autoHideMs);
      return () => clearTimeout(t);
    }
  }, [autoHideMs, onClose]);

  const guides: Record<string, { title: string; text: string }> = {
    teahouse: {
      title: '茶馆说书人',
      text: '说书人将讲述一段江湖传闻。选择你的回应，将影响你与各方势力的关系。',
    },
    billboard: {
      title: '悬赏公告栏',
      text: '这里记录着江湖上的赏金任务。选择接受或放弃，每次抉择都会影响你的声望。',
    },
    inn: {
      title: '客栈掌柜',
      text: '江湖客栈是各方势力汇聚之地。与掌柜交谈，可能获得意想不到的情报或物品。',
    },
    merchant: {
      title: '神秘商贩',
      text: '神秘商贩行踪不定，他的货物也颇为古怪。谨慎选择，可能带来好运或麻烦。',
    },
    enemy: {
      title: '遭遇敌人',
      text: '前方有敌人出没！点击后进入战斗。使用格挡（空格）和反击（鼠标左键）来取胜。',
    },
  };

  const guide = guides[cardType] || {
    title: '卡牌选择',
    text: '请选择你想要采取的行动。每个选择都会影响后续的故事发展。',
  };

  return (
    <div className={`card-draw-guide ${!visible ? 'card-draw-guide--hidden' : ''}`}>
      <span className="card-draw-guide__icon">💡</span>
      <div className="card-draw-guide__text">
        <span className="card-draw-guide__title">{guide.title}</span>
        {guide.text}
      </div>
      {onClose && (
        <button className="card-draw-guide__close" onClick={() => { setVisible(false); onClose(); }}>
          ✕
        </button>
      )}
    </div>
  );
};

export default CardDrawGuide;
